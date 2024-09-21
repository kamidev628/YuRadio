#ifndef IMAGELOADER_H
#define IMAGELOADER_H

#include <QFuture>
#include <QPixmap>

#include <QUrl>

#include "network/networkmanager.h"

class ImageLoader {
public:
  using FutureImage = QFuture<QPixmap>;

public:
  explicit ImageLoader(NetworkManager *manager);

  FutureImage load(const QUrl &url);

private:
  NetworkManager *m_manager;
};

#endif /* !IMAGELOADER_H */
