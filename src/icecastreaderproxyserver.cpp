#include <QLoggingCategory>
Q_LOGGING_CATEGORY(icecastReaderProxyServerLog,
                   "YuRadio.IcecastReaderProxyServer")

#include <QNetworkReply>
#include <QTcpServer>
#include <QTcpSocket>

#include "icecastreaderproxyserver.h"
#include "network.h"

constexpr int ICY_MULTIPLIER = 16;

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
  if (m_client) {
    m_client->disconnectFromHost();
  }
  if (m_reply) {
    m_reply->abort();
  }

  m_targetSource = targetSource;
}

QUrl IcecastReaderProxyServer::targetSource() const {
  return m_targetSource;
}

quint16 IcecastReaderProxyServer::serverPort() const {
  return m_server->serverPort();
}

void IcecastReaderProxyServer::clientConnected() {
  m_client = m_server->nextPendingConnection();

  QNetworkRequest request(m_targetSource);
  request.setRawHeader("Icy-MetaData", "1");
  request.setRawHeader("Connection", "keep-alive");

  m_reply = m_networkManager->get(request);

  connect(m_client, &QTcpSocket::disconnected, m_reply, &QObject::deleteLater);
  connect(m_client, &QTcpSocket::disconnected, m_client, &QObject::deleteLater);

  connect(m_reply, &QNetworkReply::readyRead, this,
          &IcecastReaderProxyServer::replyReadHeaders,
          Qt::SingleShotConnection);
  connect(m_reply, &QNetworkReply::finished, m_reply, [this]() {
    qCDebug(icecastReaderProxyServerLog) << "Reply finished";

    m_reply->deleteLater();

    int statusCode =
      m_reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QByteArray reasonPhrase =
      m_reply->attribute(QNetworkRequest::HttpReasonPhraseAttribute)
        .toByteArray();
    if (!statusCode || reasonPhrase.isEmpty()) {
      statusCode = 500;
      reasonPhrase = "Internal Server Error";
    }

    if (m_client) {
      m_client->write(QString("HTTP/1.1 %1 %2\r\n\r\n")
                        .arg(statusCode)
                        .arg(reasonPhrase)
                        .toLocal8Bit());
      m_client->disconnectFromHost();
    }
  });
}

void IcecastReaderProxyServer::replyReadHeaders() {
  qCDebug(icecastReaderProxyServerLog)
    << "Headers:" << m_reply->rawHeaderPairs();

  bool metaIntParsed;
  m_icyMetaInt = m_reply->hasRawHeader("icy-metaint"_L1)
                   ? m_reply->rawHeader("icy-metaint"_L1).toInt(&metaIntParsed)
                   : 0;
  m_bytesRead = 0;
  m_icyMetaLeft = 0;
  m_icyMetaDataBuffer.clear();

  if (m_icyMetaInt && metaIntParsed) {
    connect(m_reply, &QNetworkReply::readyRead, this,
            &IcecastReaderProxyServer::replyReadyRead);
  } else {
    connect(m_reply, &QNetworkReply::readyRead, this,
            [this]() { writeToClient(m_reply->bytesAvailable()); });
  }
}

void IcecastReaderProxyServer::writeToClient(qint64 nbytes) {
  if (!nbytes || !m_client) {
    return;
  }

  m_client->write(m_reply->read(nbytes));
};

void IcecastReaderProxyServer::replyReadyRead() {
  if (m_icyMetaLeft > 0) {
    qint64 numRead = qMin(m_icyMetaLeft, m_reply->bytesAvailable());

    m_icyMetaLeft -= static_cast<int>(numRead);
    m_icyMetaDataBuffer.append(m_reply->read(numRead));
    if (m_icyMetaLeft > 0) {
      return;
    }

    readIcyMetaData();
  }

  qint64 bytesRead =
    qMin(m_reply->bytesAvailable(), m_icyMetaInt - m_bytesRead);
  m_bytesRead += bytesRead;

  writeToClient(bytesRead);

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
        readIcyMetaData();
      }
    }

    m_bytesRead = qMin(m_reply->bytesAvailable(), m_icyMetaInt);
    writeToClient(m_bytesRead);
  }
}

void IcecastReaderProxyServer::readIcyMetaData() {
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
  m_icyMetaDataBuffer.clear();

  qCInfo(icecastReaderProxyServerLog) << "Icy-MetaData:" << m_icyMetaData;

  emit icyMetaDataChanged(m_icyMetaData);
}
