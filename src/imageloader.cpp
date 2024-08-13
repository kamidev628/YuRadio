#include <QNetworkReply>

#include "network/networkmanager.h"

#include "imageloader.h"

using FutureImage = ImageLoader::FutureImage;

ImageLoader::ImageLoader(NetworkManager *manager) : m_manager(manager) {}

FutureImage ImageLoader::load(const QUrl &url) {
  return m_manager->get(url).then(QtFuture::Launch::Async,
                                  [](const QByteArray &data) {
    QPixmap pixmap;
    pixmap.loadFromData(data);

    return pixmap;
  });
}
