#include <QCoreApplication>
#include <QDir>
#include <QNetworkAccessManager>
#include <QNetworkReply>

#include "hotreloaderurlinterceptor.h"

HotReloaderUrlInterceptor::HotReloaderUrlInterceptor(QString host,
                                                     QObject *parent)
    : QObject(parent), m_host(std::move(host)),
      m_networkManager(new QNetworkAccessManager(this)) {}

void HotReloaderUrlInterceptor::setModules(const QStringList &modules) {
  m_modules = modules;
  m_cachedModulesPaths.clear();

  QUrl hotreloaderServerUrl;
  hotreloaderServerUrl.setScheme("http");
  hotreloaderServerUrl.setHost(m_host);

  for (const auto &module : m_modules) {
    hotreloaderServerUrl.setPath(
      QStringLiteral("/hotreloadermodule/%1").arg(module));

    QNetworkRequest request(hotreloaderServerUrl);
    QNetworkReply *reply = m_networkManager->get(request);

    if (!reply) {
      return;
    }

    connect(reply, &QNetworkReply::finished, this, [this, reply, module]() {
      QString path = reply->readAll();
      reply->deleteLater();

      m_cachedModulesPaths[module] = path;
      if (m_cachedModulesPaths.size() == m_modules.size()) {
        emit readyIntercept();
      }
    });
  }
}

QUrl HotReloaderUrlInterceptor::intercept(const QUrl &path, DataType /*type*/) {
  const QString kResourcePrefix = "qrc:/qt/qml";

  for (const auto &module : m_modules) {
    QString moduleWithPrefix = kResourcePrefix + "/" + module;

    if (path.toString().contains(moduleWithPrefix)) {
      QDir executablePath(QCoreApplication::applicationDirPath());

      QString modulePath = m_cachedModulesPaths[module];

      QUrl newPath;
      newPath.setScheme(QStringLiteral("http"));
      newPath.setHost(m_host);
      newPath.setPath(modulePath + path.toString().remove(moduleWithPrefix));

      return newPath;
    }
  }

  return path;
}
