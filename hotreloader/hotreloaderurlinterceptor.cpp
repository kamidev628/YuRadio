#include <QCoreApplication>
#include <QDir>
#include <QNetworkAccessManager>
#include <QNetworkReply>

#include <QJsonArray>
#include <QJsonDocument>

#include "hotreloaderurlinterceptor.h"

HotReloaderUrlInterceptor::HotReloaderUrlInterceptor(QString host,
                                                     QObject *parent)
    : QObject(parent), m_host(std::move(host)),
      m_networkManager(new QNetworkAccessManager(this)) {}

void HotReloaderUrlInterceptor::setModules(const QStringList &modules) {
  m_modules = modules;
  m_cachedFilePaths.clear();

  QUrl hotreloaderServerUrl;
  hotreloaderServerUrl.setScheme("http");
  hotreloaderServerUrl.setHost(m_host);

  hotreloaderServerUrl.setPath(QStringLiteral("/hotreloader/watched/files"));

  QNetworkRequest request(hotreloaderServerUrl);
  QNetworkReply *reply = m_networkManager->get(request);

  if (!reply) {
    return;
  }

  connect(reply, &QNetworkReply::finished, this, [this, reply]() {
    QJsonArray files = QJsonDocument::fromJson(reply->readAll()).array();
    reply->deleteLater();

    for (const auto &file : files) {
      QString fileName = file.toString().split("/").last();
      m_cachedFilePaths[fileName] = file.toString();
    }
    emit readyIntercept();
  });
}

QUrl HotReloaderUrlInterceptor::intercept(const QUrl &path, DataType /*type*/) {
  const QString kResourcePrefix = "qrc:/qt/qml";

  for (const auto &module : m_modules) {
    QString moduleWithPrefix = kResourcePrefix + "/" + module;

    if (path.toString().contains(moduleWithPrefix)) {
      QString fileName = path.toString().split("/").last();

      QUrl newPath;
      newPath.setScheme(QStringLiteral("http"));
      newPath.setHost(m_host);
      newPath.setPath(m_cachedFilePaths[fileName]);

      return newPath;
    }
  }

  return path;
}
