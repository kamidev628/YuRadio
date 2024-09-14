#include <QLoggingCategory>
Q_LOGGING_CATEGORY(androidMediaSessionLog, "YuRadio.androidMediaSessionLog")

#include <QMimeDatabase>
#include <QMimeType>
#include <QPainter>
#include <QSvgRenderer>
#include <QTcpServer>
#include <QTcpSocket>

#include "androidmediasessionimageprovider.h"
#include "network/networkmanager.h"

using namespace Qt::StringLiterals;
using namespace std::chrono_literals;

/**
 * @brief Supported Image file types for Android
 */
const QStringList k_supportedFileFormats = {".bmp",  ".gif",  ".jpg",  ".png",
                                            ".webp", ".heif", ".heic", ".avif"};

AndroidMediaSessionImageProvider::AndroidMediaSessionImageProvider(
  QObject *parent)
    : QObject(parent), m_server(new QTcpServer(this)),
      m_networkManager(new NetworkManager(this)) {
  QMimeDatabase mimeDatabase;
  for (const QString &supportedFileFormat : k_supportedFileFormats) {
    QMimeType mimeType = mimeDatabase.mimeTypeForFile(supportedFileFormat);
    Q_ASSERT(!mimeType.name().isEmpty());
    m_supportedMimeTypes << mimeType.name();
  }

  if (!m_server->listen()) {
    qCDebug(androidMediaSessionLog) << m_server->errorString();
    return;
  }

  m_networkManager->setTransferTimeout(5s);

  connect(m_server, &QTcpServer::newConnection, this,
          &AndroidMediaSessionImageProvider::clientConnected);
}

void AndroidMediaSessionImageProvider::setImageSource(const QUrl &source) {
  m_imageSource = source;
}

void AndroidMediaSessionImageProvider::clientConnected() {
  qCDebug(androidMediaSessionLog) << "Client Connected";

  QTcpSocket *client = m_server->nextPendingConnection();

  connect(client, &QTcpSocket::readyRead, this,
          [this, client]() { clientReadyRead(client); });
  connect(client, &QTcpSocket::disconnected, client, &QObject::deleteLater);
}

QUrl AndroidMediaSessionImageProvider::imageUrl() const {
  if (!m_server->isListening()) {
    return m_imageSource;
  }

  QUrl url;
  url.setScheme(u"http"_s);
  url.setHost(u"127.0.0.1"_s);
  url.setPort(m_server->serverPort());

  QUrlQuery query;
  query.addQueryItem(u"q"_s, m_imageSource.url());
  url.setQuery(query);

  return url;
}

void AndroidMediaSessionImageProvider::clientReadyRead(QTcpSocket *client) {
  (void)client->readAll();

  if (!m_imageSource.isValid()) {
    clientWriteDefaultImage(client);
    return;
  }

  QString fileSuffix = QFileInfo(m_imageSource.fileName()).suffix();
  if (!fileSuffix.isEmpty() &&
      !k_supportedFileFormats.contains("." + fileSuffix)) {
    qCDebug(androidMediaSessionLog)
      << "FileFormat not supported:" << fileSuffix;
    clientWriteDefaultImage(client);
    return;
  }

  QNetworkRequest request(m_imageSource);

  QNetworkReply *reply = m_networkManager->get(request);
  connect(reply, &QNetworkReply::finished, client, [this, reply, client]() {
    if (reply->error() ||
        !m_supportedMimeTypes.contains(reply->rawHeader("Content-Type"_ba))) {

      clientWriteDefaultImage(client);
    } else {
      client->write("HTTP/1.1 200 OK\r\n"_ba);

      for (const QByteArray &header : reply->rawHeaderList()) {
        client->write(header + ": "_ba + reply->rawHeader(header) + "\r\n"_ba);
      }
      client->write("\r\n"_ba);
      client->write(reply->readAll());
    }
  });
  connect(client, &QTcpSocket::disconnected, reply, &QNetworkReply::abort);
  connect(client, &QTcpSocket::readyRead, reply, &QNetworkReply::abort);
  connect(reply, &QNetworkReply::finished, reply, &QObject::deleteLater);
}

void AndroidMediaSessionImageProvider::clientWriteDefaultImage(
  QTcpSocket *client) {
  QImage defaultImage(u":/qt/qml/YuRadioContents/images/shortwave.png"_s);

  QByteArray imageData;
  QBuffer buffer(&imageData);
  defaultImage.save(&buffer, "PNG");

  client->write("HTTP/1.1 200 OK\r\n"_ba);
  client->write("Content-Type: image/png\r\n"_ba);
  client->write("Content-Length: "_ba + QByteArray::number(imageData.length()) +
                "\r\n"_ba);
  client->write("\r\n"_ba);
  client->write(imageData);
}
