#include <QCoreApplication>
#include <QDir>
#include <QNetworkAccessManager>
#include <QNetworkReply>

#include <QJsonArray>
#include <QJsonDocument>

#include "hotreloader.h"
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
  hotreloaderServerUrl.setPort(HOTRELOADER_HTTP_PORT);

  QNetworkRequest request(hotreloaderServerUrl);
  QNetworkReply *reply = m_networkManager->get(request);

  if (!reply) {
    return;
  }

  connect(reply, &QNetworkReply::finished, this, [this, reply]() {
    QJsonArray files = QJsonDocument::fromJson(reply->readAll()).array();
    reply->deleteLater();

    for (const auto &file : files) {
      QStringList fileDirs = file.toString().split("/");

      for (const auto &module : m_modules) {
        if (fileDirs.contains(module)) {
          QString fileName = fileDirs.last();
          m_cachedFilePaths[fileName + "_" + module] = file.toString();
        }
      }
    }
    emit readyIntercept();
  });
}

QUrl HotReloaderUrlInterceptor::intercept(const QUrl &path, DataType type) {
  if (type == DataType::QmldirFile) {
    return path;
  }

  const QString kResourcePrefix = "qrc:/qt/qml";

  for (const auto &module : m_modules) {
    QString moduleWithPrefix = kResourcePrefix + "/" + module;

    if (path.toString().contains(moduleWithPrefix)) {
      QString fileName = path.toString().split("/").last();
      QString cachedFilePath = fileName + "_" + module;
      if (!m_cachedFilePaths.contains(cachedFilePath)) {
        return path;
      }

      QUrl newPath;
      newPath.setScheme(QStringLiteral("http"));
      newPath.setHost(m_host);
      newPath.setPort(HOTRELOADER_HTTP_PORT);
      newPath.setPath(m_cachedFilePaths[fileName + "_" + module]);

      return newPath;
    }
  }

  return path;
}
