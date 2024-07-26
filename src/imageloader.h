#ifndef IMAGELOADER_H
#define IMAGELOADER_H

#include <QFuture>
#include <QPixmap>

#include <QUrl>

#include "network/networkmanager.h"

class ImageLoader {
public:
  struct ImageReply {
    QFuture<QPixmap> future;
    ReplyPointer reply;
  };

  using FutureImage = ImageReply;

public:
  ImageLoader(NetworkManager *manager);

  FutureImage load(const QUrl &url);

private:
  NetworkManager *m_manager;
};

#endif /* !IMAGELOADER_H */
