#include <QStandardPaths>

#include "networkmanagerfactory.h"

#include "networkmanager.h"

NetworkManagerFactory::NetworkManagerFactory(QObject *parent)
    : QObject(parent) {}

QNetworkAccessManager *NetworkManagerFactory::create(QObject *parent) {
  auto *networkAccessManager = new NetworkManager(parent);
  auto *diskCache = new QNetworkDiskCache(parent);

  diskCache->setCacheDirectory(
    QStandardPaths::writableLocation(QStandardPaths::CacheLocation));
  networkAccessManager->setCache(diskCache);

  return networkAccessManager;
}
