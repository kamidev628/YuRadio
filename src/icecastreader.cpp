#include <QLoggingCategory>
Q_LOGGING_CATEGORY(icecastReaderLog, "YuRadio.IcecastReader")

#include <QNetworkAccessManager>
#include <QNetworkProxy>
#include <QNetworkReply>

#include <QRegularExpression>
#include <QRegularExpressionMatch>
#include <QScopeGuard>

#include <memory>

#include "icecastreader.h"

using namespace Qt::StringLiterals;

constexpr int ICY_MULTIPLIER = 16;

constexpr qint64 kAudioBufferMinSizeMs = 5000;
constexpr qint64 kAudioBufferMaxSizeMs = 20000;
constexpr qint64 kRadioMaxBitrate = 320;

constexpr qint64 kAudioBufferMinSize = 60000;
constexpr qint64 kAudioBufferMaxSize =
  kRadioMaxBitrate * kAudioBufferMaxSizeMs / 8;

constexpr qint64 kAudioBufferCriticalMaxSize =
  kAudioBufferMaxSize - kAudioBufferMinSize;

IcecastReader::IcecastReader(QObject *parent)
    : QObject(parent), m_icyMetaInt(0), m_icyMetaLeft(0),
      m_buffer(kAudioBufferMaxSize), m_networkManager(new NetworkManager(this)),
      m_reply(nullptr), m_bytesRead(0) {
  m_networkManager->setRawHeader("Icy-MetaData", "1");

  m_thread = std::make_unique<QThread>();
  moveToThread(m_thread.get());
  m_thread->start();
}

IcecastReader::~IcecastReader() {
  QMetaObject::invokeMethod(this, &IcecastReader::cleanup);
  m_thread->wait();
}

void IcecastReader::replyReadyRead() {
  auto scopeGuard = qScopeGuard([this]() { m_downloadTimer.restart(); });

  measureDownloadTime();

  if (m_icyMetaLeft > 0) {
    qint64 numRead = qMin(m_icyMetaLeft, m_reply->bytesAvailable());

    m_icyMetaLeft -= static_cast<int>(numRead);
    m_icyMetaDataBuffer.append(m_reply->read(numRead));
    if (m_icyMetaLeft > 0) {
      return;
    }

    metaDataRead();
  }

  qint64 bytesRead =
    qMin(m_reply->bytesAvailable(), m_icyMetaInt - m_bytesRead);
  m_bytesRead += bytesRead;

  if (!writeBuffer(bytesRead)) {
    return;
  }

  while (m_reply->bytesAvailable()) {
    QByteArray icyLengthByte = m_reply->read(1);
    auto icyLength = static_cast<uint8_t>(*icyLengthByte);

    if (icyLength) {
      int icyMetaDataLength = icyLength * ICY_MULTIPLIER;

      qint64 icyNumRead = qMin(m_reply->bytesAvailable(), icyMetaDataLength);

      m_icyMetaLeft = icyMetaDataLength - static_cast<int>(icyNumRead);
      if (icyNumRead) {
        m_icyMetaDataBuffer = m_reply->read(icyNumRead);
      }

      if (!m_icyMetaLeft) {
        metaDataRead();
      }
    }

    m_bytesRead = qMin(m_reply->bytesAvailable(), m_icyMetaInt);
    if (!writeBuffer(m_bytesRead)) {
      return;
    }
  }
}

bool IcecastReader::writeBuffer(qint64 bytes) {
  if (!bytes) {
    return true;
  }

  m_buffer.write(m_reply->read(bytes));

  if (m_buffer.size() >= kAudioBufferCriticalMaxSize) {
    stop();
    return false;
  }

  if (m_buffer.size() >= m_minimumBufferSize) {
    emit audioStreamBufferReady();
  }

  return true;
}

void IcecastReader::start(const QUrl &url) {
  QMetaObject::invokeMethod(this, [this, url]() { startImpl(url); });
}

void IcecastReader::stop() {
  QMetaObject::invokeMethod(this, &IcecastReader::stopImpl);
}

qint64 IcecastReader::minimumBufferSize() const {
  return m_minimumBufferSize;
}

QIODevice *IcecastReader::audioStreamBuffer() {
  return &m_buffer;
}

void IcecastReader::metaDataRead() {
  m_icyMetaData.clear();

  /*
   * NOTE: Icecast metadata structured in following way:
   * StreamTitle='...';StreamUrl='...';\0\0\0
   *
   * NOTE: The regexp will fail in the following case:
   * StreamTitle='foo bar baz'; foo';StreamUrl='...'
   * This can't be prevented due to non-escaped characters(';)
   * 
   */
  static QRegularExpression re(R"((?<key>[a-zA-Z]+)='(?<value>.*?)';)");

  for (const QRegularExpressionMatch &match :
       re.globalMatch(m_icyMetaDataBuffer)) {
    QString key = match.captured("key");
    QString value = match.captured("value");

    m_icyMetaData[key] = value;
  }

  qCInfo(icecastReaderLog) << "Icy-MetaData:" << m_icyMetaData;

  emit icyMetaDataFetched(m_icyMetaData);
}

void IcecastReader::readHeaders() {
  qCDebug(icecastReaderLog) << "Headers:" << m_reply->rawHeaderPairs();

  bool m_containsIcyHeaders = m_reply->hasRawHeader("icy-name"_L1) ||
                              m_reply->hasRawHeader("icy-metaint"_L1);

  emit icecastStation(m_containsIcyHeaders);

  if (!m_containsIcyHeaders) {
    return;
  }

  bool metaIntParsed;
  m_icyMetaInt = m_reply->hasRawHeader("icy-metaint"_L1)
                   ? m_reply->rawHeader("icy-metaint"_L1).toInt(&metaIntParsed)
                   : 0;

  bool bitrateParsed;
  m_bitrate = m_reply->rawHeader("icy-br"_L1).toInt(&bitrateParsed);

  QLatin1StringView audioInfoHeader;
  if (!bitrateParsed &&
      (m_reply->hasRawHeader(audioInfoHeader = "ice-audio-info"_L1) ||
       m_reply->hasRawHeader(audioInfoHeader = "icy-audio-info"_L1))) {

    for (const QByteArray &info :
         m_reply->rawHeader(audioInfoHeader).split(';')) {
      /* Sometimes it's ice-bitrate, icy-bitrate or just bitrate */
      if (info.contains("bitrate"_L1)) {
        QList<QByteArray> splitted = info.split('=');

        if (splitted.size() > 1) {
          m_bitrate = splitted[1].toInt(&bitrateParsed);
        }
      }
    }
  }

  if (!bitrateParsed) {
    m_bitrate = kRadioMaxBitrate;
  }

  m_minimumBufferSize =
    qMax(kAudioBufferMinSizeMs * m_bitrate / 8, kAudioBufferMinSize);

  qint64 numPortions = qCeil(qreal(m_minimumBufferSize) / 33000);

  m_minimumBufferSize = numPortions * 33000;

  qCInfo(icecastReaderLog) << "Bitrate:" << m_bitrate;
  qCInfo(icecastReaderLog) << "MinimumBufferSize:" << m_minimumBufferSize;
  qCInfo(icecastReaderLog) << "Icy-metaint:" << m_icyMetaInt;

  m_downloadTimer.start();
  connect(m_reply.get(), &QIODevice::readyRead, this,
          &IcecastReader::replyReadyRead, Qt::QueuedConnection);
}

void IcecastReader::reset() {
  if (m_buffer.isOpen()) {
    m_buffer.skip(m_buffer.bytesAvailable());
    m_buffer.close();
  }

  m_averageSpeed = 0;
  if (m_reply) {
    m_reply->disconnect(this);
    m_reply = nullptr;
  }

  m_bytesRead = 0;
  m_icyMetaLeft = 0;
  m_icyMetaInt = 0;
}

void IcecastReader::cleanup() {
  stop();
  m_thread->quit();
}

void IcecastReader::startImpl(const QUrl &url) {
  if (!url.isValid()) {
    qCWarning(icecastReaderLog)
      << "Failed to start IcecastReader. Invalid Url provided";
    return;
  }

  stop();

  m_buffer.open(QIODevice::ReadWrite | QIODevice::Unbuffered);

  NetworkResponse response = m_networkManager->get(url);

  m_reply = response.reply;

  connect(m_reply.get(), &QNetworkReply::readyRead, this,
          &IcecastReader::readHeaders,
          static_cast<Qt::ConnectionType>(Qt::SingleShotConnection |
                                          Qt::QueuedConnection));
}

void IcecastReader::stopImpl() {
  qCInfo(icecastReaderLog) << "IcecastReader stopped";

  reset();

  emit stopped();
}

void IcecastReader::measureDownloadTime() {
  if (m_downloadTimer.isValid()) {
    const qreal SMOOTHING_FACTOR = 0.1;

    qint64 elapsed = m_downloadTimer.elapsed();
    if (elapsed) {
      qreal lastSpeed = qreal(m_reply->bytesAvailable()) / qreal(elapsed);

      if (m_averageSpeed > 0) {
        m_averageSpeed = SMOOTHING_FACTOR * lastSpeed +
                         (1 - SMOOTHING_FACTOR) * m_averageSpeed;
      } else {
        m_averageSpeed = lastSpeed;
      }

      qCInfo(icecastReaderLog) << "Download speed:" << m_averageSpeed << "KB/s";
    }
  }
}
