#ifndef ANDROIDMEDIASESSIONIMAGEPROVIDER
#define ANDROIDMEDIASESSIONIMAGEPROVIDER

#include <QObject>
#include <QPointer>
#include <QUrl>

class QTcpServer;
class QTcpSocket;
class NetworkManager;
class QNetworkReply;

class AndroidMediaSessionImageProvider : public QObject {
  Q_OBJECT

public:
  explicit AndroidMediaSessionImageProvider(QObject *parent = nullptr);

  void setImageSource(const QUrl &source);
  QUrl imageUrl() const;

private slots:
  void clientConnected();
  void clientReadyRead(QTcpSocket *client);
  void clientWriteDefaultImage(QTcpSocket *client);

private:
  QTcpServer *m_server;
  NetworkManager *m_networkManager;

  QPointer<QNetworkReply> m_reply = nullptr;

  QStringList m_supportedMimeTypes;
  QUrl m_imageSource;
};

#endif /* !ANDROIDMEDIASESSIONIMAGEPROVIDER */
