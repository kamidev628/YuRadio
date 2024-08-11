#ifndef ITUNESMUSICINFOPROVIDERBACKEND_H
#define ITUNESMUSICINFOPROVIDERBACKEND_H

#include "musicinfoproviderbackend.h"
#include "network/networkmanager.h"

class QNetworkAccessManager;

class ItunesMusicInfoProviderBackend : public MusicInfoProviderBackend {
  Q_OBJECT

public:
  ItunesMusicInfoProviderBackend(QObject *parent = nullptr);

  void provide(const QString &searchString) override;

private slots:
  void handleReplyData(const QByteArray &data);

private:
  NetworkManager *m_apiManager;
  QString m_searchTerm;
};

#endif /* !ITUNESMUSICINFOPROVIDERBACKEND_H */
