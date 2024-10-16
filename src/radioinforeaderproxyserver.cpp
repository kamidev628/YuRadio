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
constexpr qint64 MAXIMUM_READ_BUFFER_SIZE = 200_KiB;

RadioInfoReaderProxyServer::RadioInfoReaderProxyServer(
  bool streamIcecastMetadata, QObject *parent)
    : QObject(parent), m_server(new QTcpServer(this)),
      m_networkManager(new NetworkManager(this)), m_numberActiveReplies(0),
      m_capturingEnabled(false),
      m_streamIcecastMetadata(streamIcecastMetadata) {
  connect(m_server, &QTcpServer::newConnection, this,
          &RadioInfoReaderProxyServer::clientConnected);
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
    qCDebug(radioInfoReaderLog) << "Client message:" << client->readAll();
    makeRequest(client);
  });

  connect(client, &QTcpSocket::disconnected, this,
          []() { qCDebug(radioInfoReaderLog) << "Client disconnected"; });
  connect(client, &QTcpSocket::disconnected, client, &QObject::deleteLater);
}

void RadioInfoReaderProxyServer::makeRequest(QTcpSocket *client) {
  QUrl streamSource = targetSource();

  QNetworkRequest request(streamSource);
  request.setRawHeader("Icy-MetaData"_ba, "1"_ba);
  request.setRawHeader("Connection"_ba, "keep-alive"_ba);
  request.setRawHeader("Accept-Encoding"_ba, "identity"_ba);

  QNetworkReply *reply = m_networkManager->get(request);
  onRequestCreated(reply);

  reply->ignoreSslErrors();
  reply->setReadBufferSize(MAXIMUM_READ_BUFFER_SIZE);

  connect(reply, &QNetworkReply::readyRead, this, [this, reply, client]() {
    replyReadHeaders(reply, client);
  }, Qt::SingleShotConnection);
  connect(reply, &QNetworkReply::finished, reply, &QObject::deleteLater);
  connect(client, &QTcpSocket::disconnected, reply, &QObject::deleteLater);
}

void RadioInfoReaderProxyServer::proxyUnsupportedFormat(
  QTcpSocket *client, const QUrl &streamSource) {
  auto *sock = new QSslSocket(client);
  onRequestCreated(sock);

  sock->setReadBufferSize(MAXIMUM_READ_BUFFER_SIZE);

  connect(sock, &QSslSocket::readyRead, client,
          [client, sock]() { client->write(sock->readAll()); });
  connect(sock, &QSslSocket::errorOccurred, client,
          [client, sock](QAbstractSocket::SocketError) {
    client->deleteLater();
    sock->deleteLater();
  });
  connect(client, &QTcpSocket::disconnected, sock, &QObject::deleteLater);

  if (streamSource.scheme() == u"https"_s) {
    sock->connectToHostEncrypted(streamSource.host(),
                                 static_cast<quint16>(streamSource.port(443)));
    sock->waitForEncrypted(3000);
  } else {
    sock->connectToHost(streamSource.host(),
                        static_cast<quint16>(streamSource.port(80)));
    sock->waitForConnected(3000);
  }

  sock->write(u"GET %1 HTTP/1.1\r\n"_s.arg(streamSource.path()).toLocal8Bit());
  sock->write("Icy-MetaData: 1\r\n");
  sock->write("Accept-Encoding: identity\r\n");
  sock->write(u"Host: %1\r\n"_s.arg(streamSource.host()).toLocal8Bit());
  sock->write("\r\n");
}

void RadioInfoReaderProxyServer::onRequestCreated(QObject *obj) {
  m_numberActiveReplies += 1;

  emit loadingChanged(m_numberActiveReplies > 0);
  connect(obj, &QObject::destroyed, this, [this]() {
    m_numberActiveReplies -= 1;

    emit loadingChanged(m_numberActiveReplies > 0);
  });
}

void RadioInfoReaderProxyServer::replyReadHeaders(QNetworkReply *reply,
                                                  QTcpSocket *client) {
  qCDebug(radioInfoReaderLog) << "Headers:" << reply->rawHeaderPairs();

  QMimeDatabase mimeDatabase;
  QString contentTypeHeader =
    reply->header(QNetworkRequest::ContentTypeHeader).toString();
  QMimeType mimeType = mimeDatabase.mimeTypeForName(contentTypeHeader);
  emit mimeTypeChanged(mimeType);

  if (QStringList{u"video/ogg"_s, u"audio/ogg"_s, u"application/ogg"_s}
        .contains(contentTypeHeader, Qt::CaseInsensitive)) {
    proxyUnsupportedFormat(client, reply->request().url());
    return;
  }

  bool metaIntParsed;
  int icyMetaInt = reply->hasRawHeader("icy-metaint"_L1)
                     ? reply->rawHeader("icy-metaint"_L1).toInt(&metaIntParsed)
                     : 0;

  int statusCode =
    reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
  if (!statusCode) {
    statusCode = reply->error() ? 500 : 200;
  }

  QByteArray reasonPhrase =
    reply->attribute(QNetworkRequest::HttpReasonPhraseAttribute).toByteArray();
  if (reasonPhrase.isEmpty()) {
    reasonPhrase = reply->error() ? "Internal Server Error"_ba : "OK"_ba;
  }

  QStringList dropHeaders = {u"Transfer-Encoding"_s, u"Connection"_s};
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
  client->write("Connection: keep-alive\r\n");
  client->write("\r\n"_ba);

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

  return true;
}

void RadioInfoReaderProxyServer::forwardNetworkReply(QNetworkReply *reply,
                                                     QTcpSocket *client) {
  if (validateNetworkReply(reply, client)) {
    QByteArray songData = reply->readAll();
    client->write(songData);

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
  QReadLocker lock(&m_lock);
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
