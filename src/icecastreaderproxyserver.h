#ifndef ICECASTREADERPROXYSERVER_H
#define ICECASTREADERPROXYSERVER_H

#include <QObject>
#include <QPointer>
#include <QUrl>
#include <QVariantMap>

class QTcpServer;
class QTcpSocket;
class QNetworkReply;
class NetworkManager;

class IcecastReaderProxyServer : public QObject {
  Q_OBJECT

public:
  IcecastReaderProxyServer(QObject *parent = nullptr);

  void setTargetSource(const QUrl &targetSource);
  QUrl targetSource() const;

  quint16 serverPort() const;

signals:
  void icyMetaDataChanged(const QVariantMap &icyMetaData);
  void loadingChanged(bool loading);

private slots:
  void clientConnected();
  void replyReadHeaders();
  void replyReadyRead();
  void readIcyMetaData();
  void replyReadyReadForward();

private:
  QTcpServer *m_server = nullptr;
  NetworkManager *m_networkManager = nullptr;
  QPointer<QTcpSocket> m_client = nullptr;
  QPointer<QNetworkReply> m_reply = nullptr;
  QUrl m_targetSource;

  qint64 m_songBytesRead;
  QByteArray m_icyMetaDataBuffer;
  QVariantMap m_icyMetaData;

  int m_icyMetaInt;
  int m_icyMetaLeft;
};

#endif /* !ICECASTREADERPROXYSERVER_H */
