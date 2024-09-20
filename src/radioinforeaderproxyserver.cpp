#include <QLoggingCategory>
Q_LOGGING_CATEGORY(radioInfoReaderLog, "YuRadio.RadioInfoReaderProxyServer")

#include <QNetworkInformation>
#include <QNetworkReply>
#include <QTcpServer>
#include <QTcpSocket>

#include "memoryliterals.h"
#include "network/networkmanager.h"
#include "radioinforeaderproxyserver.h"

using namespace MemoryLiterals;
using namespace Qt::StringLiterals;
using namespace std::chrono_literals;

constexpr int ICY_MULTIPLIER = 16;
constexpr qint64 MAXIMUM_WRITE_BUFFER_SIZE = 600_KiB;

RadioInfoReaderProxyServer::RadioInfoReaderProxyServer(QObject *parent)
    : QObject(parent), m_server(new QTcpServer(this)),
      m_networkManager(new NetworkManager(this)), m_parseIcecastInfo(true) {
  connect(m_server, &QTcpServer::newConnection, this,
          &RadioInfoReaderProxyServer::clientConnected);

  m_thread = std::make_unique<QThread>();
  m_thread->setObjectName("RadioInfoReaderProxyServerThread"_L1);
  moveToThread(m_thread.get());

  m_thread->start();

  m_networkManager->setTransferTimeout(10s);

  if (!m_server->listen()) {
    qCWarning(radioInfoReaderLog) << m_server->errorString();
    return;
  }
}

RadioInfoReaderProxyServer::~RadioInfoReaderProxyServer() {
  m_thread->quit();
  m_thread->wait();
}

void RadioInfoReaderProxyServer::setTargetSource(const QUrl &targetSource) {
  QWriteLocker locker(&m_lock);
  m_targetSource = targetSource;
}

QUrl RadioInfoReaderProxyServer::targetSource() const {
  QReadLocker locker(&m_lock);
  return m_targetSource;
}

void RadioInfoReaderProxyServer::shouldParseIcecastInfo(bool shouldParse) {
  QWriteLocker locker(&m_lock);
  m_parseIcecastInfo = shouldParse;
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

  connect(client, &QTcpSocket::readyRead, this, [this, client]() {
    (void)client->readAll();
    makeRequest(client);
  });
}

void RadioInfoReaderProxyServer::makeRequest(QTcpSocket *client) {
  QNetworkRequest request(m_targetSource);
  request.setRawHeader("Icy-MetaData"_ba, "1"_ba);
  request.setRawHeader("Connection"_ba, "keep-alive"_ba);

  QNetworkReply *reply = m_networkManager->get(request);

  connect(client, &QTcpSocket::disconnected, reply, &QNetworkReply::abort);
  connect(client, &QTcpSocket::disconnected, client, &QObject::deleteLater);
  connect(client, &QTcpSocket::readyRead, reply, &QNetworkReply::abort);

  connect(reply, &QNetworkReply::readyRead, client, [this, reply, client]() {
    replyReadHeaders(reply, client);
  }, Qt::SingleShotConnection);
  connect(reply, &QNetworkReply::requestSent, this,
          [this]() { emit loadingChanged(true); });
  connect(reply, &QNetworkReply::errorOccurred, client,
          [this, client](QNetworkReply::NetworkError err) {
    auto *networkInfo = QNetworkInformation::instance();

    if (err == QNetworkReply::TemporaryNetworkFailureError && networkInfo) {
      connect(networkInfo, &QNetworkInformation::reachabilityChanged, client,
              [this, client,
               networkInfo](QNetworkInformation::Reachability reachability) {
        if (reachability == QNetworkInformation::Reachability::Online) {
          makeRequest(client);
          networkInfo->disconnect(client);
        }
      });
    }
  });
  connect(reply, &QNetworkReply::finished, reply, &QObject::deleteLater);
  connect(reply, &QNetworkReply::finished, this,
          [this]() { emit loadingChanged(false); });
}

void RadioInfoReaderProxyServer::replyReadHeaders(QNetworkReply *reply,
                                                  QTcpSocket *client) {
  qCDebug(radioInfoReaderLog) << "Headers:" << reply->rawHeaderPairs();

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
    if (m_parseIcecastInfo) {
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

  if (m_parseIcecastInfo && icyMetaInt && metaIntParsed) {
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
  if (client->bytesToWrite() > MAXIMUM_WRITE_BUFFER_SIZE) {
    reply->abort();
    return false;
  }

  return true;
}

void RadioInfoReaderProxyServer::forwardNetworkReply(QNetworkReply *reply,
                                                     QTcpSocket *client) {
  if (validateNetworkReply(reply, client)) {
    client->write(reply->readAll());
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

  while (reply->bytesAvailable()) {
    p->songBytesRead = 0;

    QByteArray icyLengthByte = reply->read(1);
    auto icyLength = static_cast<uint8_t>(*icyLengthByte);

    if (icyLength) {
      int icyMetaDataLength = icyLength * ICY_MULTIPLIER;

      p->icyMetaDataBuffer = reply->read(icyMetaDataLength);
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
  }
}

void RadioInfoReaderProxyServer::readIcyMetaData(IcecastParserInfo *p) {
  p->icyMetaData.clear();

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
