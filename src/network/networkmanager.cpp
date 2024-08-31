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

  QString errorMessage = reply->errorString();

  if (isReplyError) {
    errorMessage += reply->readAll();
  }

  return {reply->error(), errorMessage};
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
                    u"application/json"_s);

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

  return QNetworkRequest(url);
}

void NetworkManager::setRequestHeaders(QNetworkRequest &request) {
  for (const auto &[header, value] : m_headers.asKeyValueRange()) {
    request.setRawHeader(header, value);
  }
}

QNetworkRequest NetworkManager::prepareRequest(const QUrl &url) {
  QNetworkRequest request(url);
  setRequestHeaders(request);
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

QNetworkReply *
NetworkManager::createRequest(Operation op,
                              const QNetworkRequest &originalRequest,
                              QIODevice *outgoingData) {
  QNetworkRequest request = originalRequest;
  setRequestHeaders(request);
  qCInfo(networkManagerLog).noquote()
    << u"Request[%1]: %2"_s.arg(requestMethodToString(op))
         .arg(request.url().toString());

  request.setAttribute(QNetworkRequest::CacheLoadControlAttribute,
                       QNetworkRequest::PreferCache);
  QNetworkReply *reply =
    QNetworkAccessManager::createRequest(op, request, outgoingData);

  connect(reply, &QNetworkReply::finished, this, [reply]() {
    const int httpCode = httpStatusCode(reply);
    const bool isReplyError = reply->error() != QNetworkReply::NoError;
    const bool isFromCache =
      reply->attribute(QNetworkRequest::SourceIsFromCacheAttribute).toBool();

    QString debugMessage = QString("Request Finished[%1]%2: %3")
                             .arg(requestMethodToString(reply->operation()))
                             .arg(isFromCache ? "(CACHE)" : "")
                             .arg(reply->request().url().toString());

    qCInfo(networkManagerLog).noquote() << debugMessage;

    if (isReplyError) {
      qCWarning(networkManagerLog).noquote()
        << QString("\t[NetworkError](%1): ").arg(httpCode)
        << reply->errorString();
    }
  });

  return reply;
}
