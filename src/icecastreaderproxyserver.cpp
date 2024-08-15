#include <QLoggingCategory>
Q_LOGGING_CATEGORY(icecastReaderProxyServerLog,
                   "YuRadio.IcecastReaderProxyServer")

#include <QNetworkReply>
#include <QTcpServer>
#include <QTcpSocket>

#include "icecastreaderproxyserver.h"
#include "network/networkmanager.h"

constexpr int ICY_MULTIPLIER = 16;
constexpr qint64 MAXIMUM_WRITE_BUFFER_SIZE = 200000;

using namespace Qt::StringLiterals;
using namespace std::chrono_literals;

IcecastReaderProxyServer::IcecastReaderProxyServer(QObject *parent)
    : QObject(parent), m_server(new QTcpServer(this)),
      m_networkManager(new NetworkManager(this)) {
  if (!m_server->listen()) {
    qCWarning(icecastReaderProxyServerLog) << "Failed to listen";
    return;
  }

  m_networkManager->setTransferTimeout(10s);

  connect(m_server, &QTcpServer::newConnection, this,
          &IcecastReaderProxyServer::clientConnected);
}

void IcecastReaderProxyServer::setTargetSource(const QUrl &targetSource) {
  m_targetSource = targetSource;
}

QUrl IcecastReaderProxyServer::targetSource() const {
  return m_targetSource;
}

quint16 IcecastReaderProxyServer::serverPort() const {
  return m_server->serverPort();
}

void IcecastReaderProxyServer::clientConnected() {
  if (m_reply) {
    m_reply->abort();
  }

  m_client = m_server->nextPendingConnection();

  QNetworkRequest request(m_targetSource);
  request.setRawHeader("Icy-MetaData"_ba, "1"_ba);
  request.setRawHeader("Connection"_ba, "keep-alive"_ba);

  m_reply = m_networkManager->get(request);

  connect(m_client, &QTcpSocket::disconnected, m_reply, &QObject::deleteLater);
  connect(m_client, &QTcpSocket::disconnected, m_client, &QObject::deleteLater);

  connect(m_reply, &QNetworkReply::readyRead, this,
          &IcecastReaderProxyServer::replyReadHeaders,
          Qt::SingleShotConnection);
  connect(m_reply, &QNetworkReply::finished, m_reply, &QObject::deleteLater);
  connect(m_reply, &QNetworkReply::finished, m_client,
          &QTcpSocket::disconnectFromHost);
  connect(m_reply, &QNetworkReply::finished, this,
          [this]() { loadingChanged(false); });
}

void IcecastReaderProxyServer::replyReadHeaders() {
  qCDebug(icecastReaderProxyServerLog)
    << "Headers:" << m_reply->rawHeaderPairs();

  loadingChanged(true);
  bool metaIntParsed;
  m_icyMetaInt = m_reply->hasRawHeader("icy-metaint"_L1)
                   ? m_reply->rawHeader("icy-metaint"_L1).toInt(&metaIntParsed)
                   : 0;
  m_songBytesRead = 0;
  m_icyMetaLeft = 0;
  m_icyMetaDataBuffer.clear();

  if (m_client) {
    int statusCode =
      m_reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    if (!statusCode) {
      statusCode = m_reply->error() ? 500 : 200;
    }

    QByteArray reasonPhrase =
      m_reply->attribute(QNetworkRequest::HttpReasonPhraseAttribute)
        .toByteArray();
    if (reasonPhrase.isEmpty()) {
      reasonPhrase = m_reply->error() ? "Internal Server Error"_ba : "OK"_ba;
    }

    /* We are ready to send data */
    m_client->write(u"HTTP/1.1 %1 %2\r\n\r\n"_s.arg(statusCode)
                      .arg(reasonPhrase)
                      .toLocal8Bit());
  }

  if (m_icyMetaInt && metaIntParsed) {
    connect(m_reply, &QNetworkReply::readyRead, this,
            &IcecastReaderProxyServer::replyReadyRead);
  } else {
    connect(m_reply, &QNetworkReply::readyRead, this,
            &IcecastReaderProxyServer::replyReadyReadForward);
  }
}

void IcecastReaderProxyServer::replyReadyReadForward() {
  if (m_client->bytesToWrite() > MAXIMUM_WRITE_BUFFER_SIZE) {
    m_reply->abort();
    return;
  }

  m_client->write(m_reply->readAll());
}

void IcecastReaderProxyServer::replyReadyRead() {
  if (m_client->bytesToWrite() > MAXIMUM_WRITE_BUFFER_SIZE) {
    m_reply->abort();
    return;
  }

  if (m_icyMetaLeft > 0) {
    QByteArray metaDataPart = m_reply->read(m_icyMetaLeft);

    m_icyMetaLeft -= static_cast<int>(metaDataPart.length());
    m_icyMetaDataBuffer.append(metaDataPart);
    if (m_icyMetaLeft > 0) {
      return;
    }

    readIcyMetaData();
  }

  Q_ASSERT(m_icyMetaInt - m_songBytesRead >= 0);
  QByteArray songData = m_reply->read(m_icyMetaInt - m_songBytesRead);
  m_songBytesRead += songData.length();

  m_client->write(songData);

  while (m_reply->bytesAvailable()) {
    m_songBytesRead = 0;

    QByteArray icyLengthByte = m_reply->read(1);
    auto icyLength = static_cast<uint8_t>(*icyLengthByte);

    if (icyLength) {
      int icyMetaDataLength = icyLength * ICY_MULTIPLIER;

      m_icyMetaDataBuffer = m_reply->read(icyMetaDataLength);
      int numRead = static_cast<int>(m_icyMetaDataBuffer.length());

      m_icyMetaLeft = icyMetaDataLength - numRead;
      if (m_icyMetaLeft) {
        return;
      }
      readIcyMetaData();
    }

    songData = m_reply->read(m_icyMetaInt);
    m_songBytesRead = songData.length();
    m_client->write(songData);
  }
}

void IcecastReaderProxyServer::readIcyMetaData() {
  m_icyMetaData.clear();

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
       re.globalMatch(m_icyMetaDataBuffer)) {
    QString key = match.captured(u"key"_s);
    QString value = match.captured(u"value"_s);

    m_icyMetaData[key] = value;
  }

  qCInfo(icecastReaderProxyServerLog) << "Icy-MetaData:" << m_icyMetaData;

  emit icyMetaDataChanged(m_icyMetaData);
}
