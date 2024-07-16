#include <QLoggingCategory>
Q_LOGGING_CATEGORY(networkManagerLog, "YuRest.NetworkManager")

#include <QJsonDocument>
#include <QJsonObject>

#include <QHttpMultiPart>
#include <QNetworkReply>

#include "json.h"
#include "network.h"

NetworkManager::NetworkManager(QObject *parent)
    : QNetworkAccessManager(parent) {
  QString applicationVersion = QCoreApplication::applicationVersion();
  if (applicationVersion.isNull()) {
    applicationVersion = "1.0";
  }

  QString applicationName = QCoreApplication::applicationName();
  if (applicationName.isNull()) {
    applicationName = "YuRest";
  }

  QString userAgent = applicationName + "/" + applicationVersion;

  setRawHeader("User-Agent", userAgent.toLatin1());
  setRawHeader("Accept", "*/*");
}

static int httpStatusCode(QNetworkReply *reply) {
  return reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
}

static QString
requestMethodToString(QNetworkAccessManager::Operation operation) {
  switch (operation) {
    case QNetworkAccessManager::HeadOperation:
      return "HEAD";
    case QNetworkAccessManager::GetOperation:
      return "GET";
    case QNetworkAccessManager::PutOperation:
      return "PUT";
    case QNetworkAccessManager::PostOperation:
      return "POST";
    case QNetworkAccessManager::DeleteOperation:
      return "DELETE";
    case QNetworkAccessManager::CustomOperation:
      return "CUSTOM";
    case QNetworkAccessManager::UnknownOperation:
    default:
      return "UNKNOWN";
  }
}

NetworkError NetworkManager::checkNetworkErrors(QNetworkReply *reply) {
  const int httpCode = httpStatusCode(reply);
  const bool isReplyError = reply->error() != QNetworkReply::NoError;

  QString debugMessage = QString("Request[%1]: %2")
                           .arg(requestMethodToString(reply->operation()))
                           .arg(reply->request().url().toString());

  qCInfo(networkManagerLog).noquote() << debugMessage;

  QString errorMessage;

  if (isReplyError) {
    QString response;
    QByteArray data = reply->isReadable() ? reply->readAll() : "";

    if (reply->header(QNetworkRequest::ContentTypeHeader)
          .toString()
          .contains("application/json")) {
      QJsonDocument json = *json::byteArrayToJson(data);

      response = json["error"].toString();
    } else {
      response = data;
    }

    errorMessage = reply->errorString() + response;

    qCWarning(networkManagerLog).noquote()
      << QString("\t[NetworkError](%1): ").arg(httpCode) << errorMessage;
  }

  return {reply->error(), errorMessage};
}

NetworkResponse NetworkManager::post(const QString &path,
                                     QHttpMultiPart *multiPart) {
  QNetworkRequest request = prepareRequest(path);

  QNetworkReply *reply = QNetworkAccessManager::post(request, multiPart);
  multiPart->setParent(reply);

  return makeFutureReply(reply);
}

NetworkResponse NetworkManager::post(const QString &path,
                                     const QVariantMap &value) {
  QNetworkRequest request = prepareRequest(path);

  request.setHeader(QNetworkRequest::KnownHeaders::ContentTypeHeader,
                    "application/json");

  QNetworkReply *reply = QNetworkAccessManager::post(
    request, QJsonDocument::fromVariant(value).toJson(QJsonDocument::Compact));

  return makeFutureReply(reply);
}

NetworkResponse NetworkManager::get(const QString &path,
                                    const QUrlQuery &parameters) {
  QNetworkRequest request = prepareRequest(path, parameters);

  QNetworkReply *reply = QNetworkAccessManager::get(request);

  return makeFutureReply(reply);
}

NetworkResponse NetworkManager::get(const QUrl &url) {
  QNetworkRequest request = prepareRequest(url);

  QNetworkReply *reply = QNetworkAccessManager::get(request);

  return makeFutureReply(reply);
}

NetworkResponse NetworkManager::put(const QString &path,
                                    const QVariantMap &value) {
  QNetworkRequest request = prepareRequest(path);

  request.setHeader(QNetworkRequest::KnownHeaders::ContentTypeHeader,
                    "application/json");

  QNetworkReply *reply = QNetworkAccessManager::put(
    request, QJsonDocument::fromVariant(value).toJson(QJsonDocument::Compact));

  return makeFutureReply(reply);
}

NetworkResponse NetworkManager::put(const QString &path,
                                    QHttpMultiPart *multiPart) {
  QNetworkRequest request = prepareRequest(path);

  QNetworkReply *reply = QNetworkAccessManager::put(request, multiPart);
  multiPart->setParent(reply);

  return makeFutureReply(reply);
}

NetworkResponse NetworkManager::deleteResource(const QString &path) {
  QNetworkRequest request = prepareRequest(path);

  QNetworkReply *reply = QNetworkAccessManager::deleteResource(request);

  return makeFutureReply(reply);
}

NetworkResponse NetworkManager::makeFutureReply(QNetworkReply *replyBase) {
  auto reply = QSharedPointer<QNetworkReply>(replyBase, [replyBase](auto) {
    replyBase->abort();
    replyBase->deleteLater();
  });
  /* NOTE: We don't want to mix parent-child relationships and smart pointers */
  reply->setParent(nullptr);

  auto replyFinished =
    QtFuture::connect(reply.get(), &QNetworkReply::finished).then([reply]() {
    auto maybeError = checkNetworkErrors(reply.get());

    if (maybeError) {
      throw std::move(maybeError);
    }

    return reply->isReadable() ? reply->readAll() : "";
  });

  return {replyFinished, reply};
}

QNetworkRequest NetworkManager::prepareRequest(const QString &path,
                                               const QUrlQuery &query) {
  QUrl url(m_baseUrl);
  url.setPath(path);

  if (!query.isEmpty()) {
    url.setQuery(query);
  }

  return prepareRequest(url);
}

QNetworkRequest NetworkManager::prepareRequest(const QUrl &url) {
  QNetworkRequest request(url);

  for (const auto &[header, value] : m_headers.asKeyValueRange()) {
    request.setRawHeader(header, value);
  }

  return request;
}

QUrl NetworkManager::baseUrl() const {
  return m_baseUrl;
}

void NetworkManager::setBaseUrl(const QUrl &newBaseUrl) {
  if (m_baseUrl == newBaseUrl) {
    return;
  }

  m_baseUrl = newBaseUrl;
  emit baseUrlChanged();
}

QByteArray NetworkManager::rawHeader(const QByteArray &header) const {
  return m_headers.value(header);
}

void NetworkManager::setRawHeader(const QByteArray &header,
                                  const QByteArray &value) {
  m_headers[header] = value;
}

void NetworkManager::removeRawHeader(const QByteArray &header) {
  m_headers.remove(header);
}
