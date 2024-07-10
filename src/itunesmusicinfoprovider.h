#ifndef ITUNESMUSICINFOPROVIDER_H
#define ITUNESMUSICINFOPROVIDER_H

#include "musicinfoprovider.h"
#include "network.h"

class QNetworkAccessManager;

class ItunesMusicInfoProvider : public MusicInfoProvider {
  Q_OBJECT
  QML_ELEMENT

public:
  ItunesMusicInfoProvider(QObject *parent = nullptr);

  void provide(const QString &searchString) override;

private slots:
  void handleReplyData(const QByteArray &data);

private:
  NetworkManager *m_apiManager;
};

#endif /* !ITUNESMUSICINFOPROVIDER_H */
