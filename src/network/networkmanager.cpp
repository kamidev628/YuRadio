#include <QLoggingCategory>
Q_LOGGING_CATEGORY(networkManagerLog, "YuRest.NetworkManager")

#include <QJsonDocument>
#include <QJsonObject>

#include <QHttpMultiPart>
#include <QNetworkReply>

#include "json.h"
#include "networkmanager.h"

using namespace Qt::StringLiterals;

NetworkManager::NetworkManager(QObject *parent)
    : QNetworkAccessManager(parent) {
  QString userAgent = applicationUserAgent();

  setRawHeader("User-Agent"_ba, userAgent.toLatin1());
  setRawHeader("Accept"_ba, "*/*"_ba);
}

static int httpStatusCode(QNetworkReply *reply) {
  return reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
}

static QString
requestMethodToString(QNetworkAccessManager::Operation operation) {
  switch (operation) {
    case QNetworkAccessManager::HeadOperation:
      return u"HEAD"_s;
    case QNetworkAccessManager::GetOperation:
      return u"GET"_s;
    case QNetworkAccessManager::PutOperation:
      return u"PUT"_s;
    case QNetworkAccessManager::PostOperation:
      return u"POST"_s;
    case QNetworkAccessManager::DeleteOperation:
      return u"DELETE"_s;
    case QNetworkAccessManager::CustomOperation:
      return u"CUSTOM"_s;
    case QNetworkAccessManager::UnknownOperation:
    default:
      return u"UNKNOWN"_s;
  }
}

NetworkError NetworkManager::checkNetworkErrors(QNetworkReply *reply) {
  const int httpCode = httpStatusCode(reply);
  const bool isReplyError = reply->error() != QNetworkReply::NoError;

  QString debugMessage =
    u"Request[%1]: %2"_s.arg(requestMethodToString(reply->operation()))
      .arg(reply->request().url().toString());

  qCInfo(networkManagerLog).noquote() << debugMessage;

  if (isReplyError) {
    QByteArray data = reply->isReadable() ? reply->readAll() : "";
    QString errorMessage = reply->errorString() + data;

    qCWarning(networkManagerLog).noquote()
      << QString("\t[NetworkError](%1): ").arg(httpCode) << errorMessage;
  }

  return {reply->error(), reply->errorString()};
}

NetworkResponse NetworkManager::post(const QString &path,
                                     QHttpMultiPart *multiPart) {
  QNetworkRequest request = prepareRequest(path);

  QNetworkReply *reply = QNetworkAccessManager::post(request, multiPart);
  multiPart->setParent(reply);

  return makeNetworkResponse(reply);
}

NetworkResponse NetworkManager::post(const QString &path,
                                     const QVariantMap &value) {
  QNetworkRequest request = prepareRequest(path);

  request.setHeader(QNetworkRequest::KnownHeaders::ContentTypeHeader,
                    u"application/json"_s);

  QNetworkReply *reply = QNetworkAccessManager::post(
    request, QJsonDocument::fromVariant(value).toJson(QJsonDocument::Compact));

  return makeNetworkResponse(reply);
}

NetworkResponse NetworkManager::get(const QString &path,
                                    const QUrlQuery &parameters) {
  QNetworkRequest request = prepareRequest(path, parameters);

  QNetworkReply *reply = QNetworkAccessManager::get(request);

  return makeNetworkResponse(reply);
}

NetworkResponse NetworkManager::get(const QUrl &url) {
  QNetworkRequest request = prepareRequest(url);

  QNetworkReply *reply = QNetworkAccessManager::get(request);

  return makeNetworkResponse(reply);
}

NetworkResponse NetworkManager::put(const QString &path,
                                    const QVariantMap &value) {
  QNetworkRequest request = prepareRequest(path);

  request.setHeader(QNetworkRequest::KnownHeaders::ContentTypeHeader,
                    "application/json");

  QNetworkReply *reply = QNetworkAccessManager::put(
    request, QJsonDocument::fromVariant(value).toJson(QJsonDocument::Compact));

  return makeNetworkResponse(reply);
}

NetworkResponse NetworkManager::put(const QString &path,
                                    QHttpMultiPart *multiPart) {
  QNetworkRequest request = prepareRequest(path);

  QNetworkReply *reply = QNetworkAccessManager::put(request, multiPart);
  multiPart->setParent(reply);

  return makeNetworkResponse(reply);
}

NetworkResponse NetworkManager::deleteResource(const QString &path) {
  QNetworkRequest request = prepareRequest(path);

  QNetworkReply *reply = QNetworkAccessManager::deleteResource(request);

  return makeNetworkResponse(reply);
}

NetworkResponse NetworkManager::makeNetworkResponse(QNetworkReply *reply) {
  auto *watcher = new QFutureWatcher<QByteArray>(reply);

  auto replyFinished = QtFuture::connect(reply, &QNetworkReply::finished)
                         .then(reply, [reply]() -> QByteArray {
    reply->deleteLater();
    auto maybeError = checkNetworkErrors(reply);

    if (maybeError) {
      throw std::move(maybeError);
    }
    Q_ASSERT(reply->isReadable());

    return reply->readAll();
  });

  watcher->setFuture(replyFinished);
  connect(watcher, &QFutureWatcher<QByteArray>::canceled, reply,
          &QNetworkReply::abort);

  return replyFinished;
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

QString NetworkManager::applicationUserAgent() {
  QString applicationVersion = QCoreApplication::applicationVersion();
  if (applicationVersion.isNull()) {
    applicationVersion = u"1.0"_s;
  }

  QString applicationName = QCoreApplication::applicationName();
  if (applicationName.isNull()) {
    applicationName = u"YuRest"_s;
  }

  return applicationName + '/'_L1 + applicationVersion;
}
