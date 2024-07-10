#include <QNetworkReply>

#include "network.h"

#include "imageloader.h"

using FutureImage = ImageLoader::FutureImage;

ImageLoader::ImageLoader(NetworkManager *manager) : m_manager(manager) {}

FutureImage ImageLoader::load(const QUrl &url) {
  auto [future, reply] = m_manager->get(url);

  auto futureImage =
    future.then(QtFuture::Launch::Async, [](const QByteArray &data) {
    QPixmap pixmap;
    pixmap.loadFromData(data);

    return pixmap;
  });

  return {futureImage, reply};
}
