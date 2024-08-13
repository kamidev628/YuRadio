#ifndef NETWORKMANAGER_H
#define NETWORKMANAGER_H

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QUrlQuery>

#include <QtQml>

#include <QFuture>

#include "networkerror.h"

using ReplyPointer = QSharedPointer<QNetworkReply>;
using NetworkResponse = QFuture<QByteArray>;

class NetworkManager : public QNetworkAccessManager {
  Q_OBJECT
  Q_PROPERTY(
    QUrl baseUrl READ baseUrl WRITE setBaseUrl NOTIFY baseUrlChanged FINAL)
  QML_ELEMENT

public:
  using QNetworkAccessManager::deleteResource;
  using QNetworkAccessManager::get;
  using QNetworkAccessManager::post;
  using QNetworkAccessManager::put;

public:
  explicit NetworkManager(QObject *parent = nullptr);

  NetworkResponse post(const QString &path, const QVariantMap &value = {});
  NetworkResponse post(const QString &path, QHttpMultiPart *multiPart);
  NetworkResponse get(const QString &path, const QUrlQuery &parameters = {});
  NetworkResponse get(const QUrl &url);
  NetworkResponse put(const QString &path, const QVariantMap &value);
  NetworkResponse put(const QString &path, QHttpMultiPart *multiPart);
  NetworkResponse deleteResource(const QString &path);

  QUrl baseUrl() const;
  void setBaseUrl(const QUrl &newBaseUrl);

  void setRawHeader(const QByteArray &header, const QByteArray &value);
  QByteArray rawHeader(const QByteArray &header) const;
  void removeRawHeader(const QByteArray &header);
  static QString applicationUserAgent();

signals:
  void baseUrlChanged();

private:
  static NetworkError checkNetworkErrors(QNetworkReply *reply);
  static NetworkResponse makeNetworkResponse(QNetworkReply *reply);

  QNetworkRequest prepareRequest(const QString &path,
                                 const QUrlQuery &query = {});
  QNetworkRequest prepareRequest(const QUrl &url);

private:
  QByteArray m_bearerToken;
  QHash<QByteArray, QByteArray> m_headers;
  QUrl m_baseUrl;
};

#endif  // NETWORKMANAGER_H
