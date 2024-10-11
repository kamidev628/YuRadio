#include <QLoggingCategory>
Q_LOGGING_CATEGORY(radioInfoReaderLog, "YuRadio.RadioInfoReaderProxyServer")

#include <QBuffer>
#include <QNetworkInformation>
#include <QNetworkReply>
#include <QTcpServer>
#include <QTcpSocket>

#include <QMimeDatabase>
#include <QMimeType>

#include "memoryliterals.h"
#include "network/networkmanager.h"
#include "radioinforeaderproxyserver.h"

using namespace MemoryLiterals;
using namespace Qt::StringLiterals;
using namespace std::chrono_literals;

constexpr int ICY_MULTIPLIER = 16;
constexpr qint64 MAXIMUM_READ_BUFFER_SIZE = 50_KiB;

RadioInfoReaderProxyServer::RadioInfoReaderProxyServer(
  bool streamIcecastMetadata, QObject *parent)
    : QObject(parent), m_server(new QTcpServer(this)),
      m_networkManager(new NetworkManager(this)), m_capturingEnabled(false),
      m_streamIcecastMetadata(streamIcecastMetadata) {
  connect(m_server, &QTcpServer::newConnection, this,
          &RadioInfoReaderProxyServer::clientConnected);

  m_networkManager->setTransferTimeout(10s);
}

RadioInfoReaderProxyServer::~RadioInfoReaderProxyServer() = default;

void RadioInfoReaderProxyServer::listen() {
  QMetaObject::invokeMethod(this, &RadioInfoReaderProxyServer::start);
}

void RadioInfoReaderProxyServer::start() {
  if (!m_server->listen()) {
    qCWarning(radioInfoReaderLog) << m_server->errorString();
  }
}

void RadioInfoReaderProxyServer::setTargetSource(const QUrl &targetSource) {
  QWriteLocker locker(&m_lock);
  m_targetSource = targetSource;
}

QUrl RadioInfoReaderProxyServer::targetSource() const {
  QReadLocker locker(&m_lock);
  return m_targetSource;
}

void RadioInfoReaderProxyServer::enableCapturing(bool enableCapture) {
  QWriteLocker locker(&m_lock);
  m_capturingEnabled = enableCapture;
}

QUrl RadioInfoReaderProxyServer::sourceUrl() const {
  QReadLocker locker(&m_lock);
  if (!m_server->isListening() || !m_targetSource.isValid()) {
    return m_targetSource;
  }

  QUrl url;
  url.setScheme(u"http"_s);
  url.setHost(u"127.0.0.1"_s);
  url.setPort(m_server->serverPort());

  QUrlQuery query;
  query.addQueryItem(u"q"_s, m_targetSource.url());
  url.setQuery(query);

  return url;
}

void RadioInfoReaderProxyServer::clientConnected() {
  QTcpSocket *client = m_server->nextPendingConnection();
  qCDebug(radioInfoReaderLog) << "Client connected";

  connect(client, &QTcpSocket::readyRead, this, [this, client]() {
    (void)client->readAll();
    makeRequest(client);
  });
  connect(client, &QTcpSocket::disconnected, this,
          []() { qCDebug(radioInfoReaderLog) << "Client disconnected"; });
}

void RadioInfoReaderProxyServer::makeRequest(QTcpSocket *client) {
  QNetworkRequest request(targetSource());
  request.setRawHeader("Icy-MetaData"_ba, "1"_ba);
  request.setRawHeader("Connection"_ba, "keep-alive"_ba);

  if (m_reply) {
    /* NOTE: Avoid emitting loadingChanged */
    m_reply->disconnect(this);
  }

  QNetworkReply *reply = m_networkManager->get(request);
  reply->ignoreSslErrors();
  reply->setReadBufferSize(MAXIMUM_READ_BUFFER_SIZE);

  m_reply = reply;

  connect(client, &QTcpSocket::disconnected, reply, &QNetworkReply::abort);
  connect(client, &QTcpSocket::disconnected, client, &QObject::deleteLater);
  connect(client, &QTcpSocket::readyRead, reply, &QNetworkReply::abort);

  connect(reply, &QNetworkReply::readyRead, client, [this, reply, client]() {
    replyReadHeaders(reply, client);
  }, Qt::SingleShotConnection);
  connect(reply, &QNetworkReply::requestSent, this,
          [this]() { emit loadingChanged(true); });
  connect(reply, &QNetworkReply::errorOccurred, client,
          [client](QNetworkReply::NetworkError err) {
    if (err != QNetworkReply::OperationCanceledError) {
      client->disconnectFromHost();
    }
  });

  connect(reply, &QNetworkReply::finished, reply, &QObject::deleteLater);
  connect(reply, &QNetworkReply::finished, this,
          [this]() { emit loadingChanged(false); });
}

void RadioInfoReaderProxyServer::replyReadHeaders(QNetworkReply *reply,
                                                  QTcpSocket *client) {
  qCDebug(radioInfoReaderLog) << "Headers:" << reply->rawHeaderPairs();

  QMimeDatabase mimeDatabase;
  QMimeType mimeType = mimeDatabase.mimeTypeForName(
    reply->header(QNetworkRequest::ContentTypeHeader).toString());
  emit mimeTypeChanged(mimeType);

  bool metaIntParsed;
  int icyMetaInt = reply->hasRawHeader("icy-metaint"_L1)
                     ? reply->rawHeader("icy-metaint"_L1).toInt(&metaIntParsed)
                     : 0;

  if (client) {
    int statusCode =
      reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    if (!statusCode) {
      statusCode = reply->error() ? 500 : 200;
    }

    QByteArray reasonPhrase =
      reply->attribute(QNetworkRequest::HttpReasonPhraseAttribute)
        .toByteArray();
    if (reasonPhrase.isEmpty()) {
      reasonPhrase = reply->error() ? "Internal Server Error"_ba : "OK"_ba;
    }

    QStringList dropHeaders = {u"Transfer-Encoding"_s};
    if (!m_streamIcecastMetadata) {
      dropHeaders << u"icy-metaint"_s;
    }

    /* We are ready to send data */
    client->write(
      u"HTTP/1.1 %1 %2\r\n"_s.arg(statusCode).arg(reasonPhrase).toLocal8Bit());
    for (const auto &header : reply->rawHeaderList()) {
      if (!dropHeaders.contains(header, Qt::CaseInsensitive)) {
        client->write(header + ": "_ba + reply->rawHeader(header) + "\r\n"_ba);
      }
    }
    client->write("\r\n"_ba);
  }

  if (icyMetaInt && metaIntParsed) {
    auto *parserInfo = new IcecastParserInfo(client);
    parserInfo->icyMetaInt = icyMetaInt;

    connect(reply, &QNetworkReply::readyRead, this,
            [this, reply, client, parserInfo]() {
      processNetworkReply(reply, parserInfo, client);
    });
  } else {
    connect(reply, &QNetworkReply::readyRead, this,
            [this, reply, client]() { forwardNetworkReply(reply, client); });
  }
}

bool RadioInfoReaderProxyServer::validateNetworkReply(QNetworkReply *reply,
                                                      QTcpSocket *client) {

  if (client->bytesToWrite() >
      MAXIMUM_READ_BUFFER_SIZE + static_cast<int>(50_KiB)) {
    qCDebug(radioInfoReaderLog) << "Client buffer overflow";
    reply->abort();
    return false;
  }

  if (client->bytesToWrite() > 0) {
    return false;
  }

  return true;
}

void RadioInfoReaderProxyServer::forwardNetworkReply(QNetworkReply *reply,
                                                     QTcpSocket *client) {
  if (validateNetworkReply(reply, client)) {
    QByteArray songData = reply->readAll();
    client->write(reply->readAll());

    emit bufferCaptured(songData, {});
  }
}

void RadioInfoReaderProxyServer::processNetworkReply(QNetworkReply *reply,
                                                     IcecastParserInfo *p,
                                                     QTcpSocket *client) {
  if (!validateNetworkReply(reply, client)) {
    return;
  }

  if (p->icyMetaLeft > 0) {
    QByteArray metaDataPart = reply->read(p->icyMetaLeft);

    if (m_streamIcecastMetadata) {
      client->write(metaDataPart);
    }

    p->icyMetaLeft -= static_cast<int>(metaDataPart.length());
    p->icyMetaDataBuffer.append(metaDataPart);
    if (p->icyMetaLeft > 0) {
      return;
    }

    readIcyMetaData(p);
  }

  Q_ASSERT(p->icyMetaInt - p->songBytesRead >= 0);
  QByteArray songData = reply->read(p->icyMetaInt - p->songBytesRead);
  p->songBytesRead += songData.length();

  client->write(songData);
  captureBuffer(songData, p);

  while (reply->bytesAvailable()) {
    p->songBytesRead = 0;

    QByteArray icyLengthByte = reply->read(1);
    auto icyLength = static_cast<uint8_t>(*icyLengthByte);

    if (m_streamIcecastMetadata) {
      client->write(icyLengthByte);
    }

    if (icyLength) {
      int icyMetaDataLength = icyLength * ICY_MULTIPLIER;

      p->icyMetaDataBuffer = reply->read(icyMetaDataLength);
      if (m_streamIcecastMetadata) {
        client->write(p->icyMetaDataBuffer);
      }
      int numRead = static_cast<int>(p->icyMetaDataBuffer.length());

      p->icyMetaLeft = icyMetaDataLength - numRead;
      if (p->icyMetaLeft) {
        return;
      }
      readIcyMetaData(p);
    }

    songData = reply->read(p->icyMetaInt);
    p->songBytesRead = songData.length();
    client->write(songData);
    captureBuffer(songData, p);
  }
}

void RadioInfoReaderProxyServer::captureBuffer(const QByteArray &buffer,
                                               const IcecastParserInfo *p) {
  if (m_capturingEnabled) {
    emit bufferCaptured(buffer, p->icyMetaData[u"StreamTitle"_s].toString());
  }
}

void RadioInfoReaderProxyServer::readIcyMetaData(IcecastParserInfo *p) {
  /*
   * NOTE: Icecast metadata structured in the following way:
   * StreamTitle='...';StreamUrl='...';\0\0\0
   *
   * NOTE: The regexp will fail in the following case:
   * StreamTitle='foo bar baz'; foo';StreamUrl='...'
   * This can't be prevented due to non-escaped characters(';)
   * 
   */
  static QRegularExpression re(uR"((?<key>[a-zA-Z]+)='(?<value>.*?)';)"_s);

  for (const QRegularExpressionMatch &match :
       re.globalMatch(p->icyMetaDataBuffer)) {
    QString key = match.captured(u"key"_s);
    QString value = match.captured(u"value"_s);

    p->icyMetaData[key] = value;
  }

  qCInfo(radioInfoReaderLog) << "Icy-MetaData:" << p->icyMetaData;

  emit icyMetaDataChanged(p->icyMetaData);
}
