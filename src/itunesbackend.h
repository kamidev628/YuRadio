#ifndef ITUNESMUSICINFOPROVIDERBACKEND_H
#define ITUNESMUSICINFOPROVIDERBACKEND_H

#include "musicinfoproviderbackend.h"
#include "network/networkmanager.h"

class QNetworkAccessManager;

class ItunesBackend : public MusicInfoProviderBackend {
  Q_OBJECT

public:
  ItunesBackend(QObject *parent = nullptr);

  void requestMusicInfo(const QString &searchString) override;
  QString backendName() const override;

private slots:
  void handleReplyData(const QByteArray &data);

private:
  NetworkManager *m_apiManager;
  QSharedPointer<QNetworkReply> m_reply;
  QString m_searchTerm;
};

#endif /* !ITUNESMUSICINFOPROVIDERBACKEND_H */
