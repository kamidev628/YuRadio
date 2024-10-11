#ifndef RADIOINFOREADERPROXYSERVER_H
#define RADIOINFOREADERPROXYSERVER_H

#include <QMimeType>
#include <QObject>
#include <QPointer>
#include <QReadWriteLock>
#include <QUrl>
#include <QVariantMap>

class QTcpServer;
class QTcpSocket;
class QNetworkReply;
class NetworkManager;
class DownloadSpeedMeasurer;
class QBuffer;

class IcecastParserInfo : public QObject {
  Q_OBJECT

public:
  explicit IcecastParserInfo(QObject *parent) : QObject(parent) {}

  qint64 songBytesRead = 0;
  QByteArray icyMetaDataBuffer;
  QVariantMap icyMetaData;

  int icyMetaInt = 0;
  int icyMetaLeft = 0;
};

class RadioInfoReaderProxyServer : public QObject {
  Q_OBJECT

public:
  explicit RadioInfoReaderProxyServer(bool streamIcecastMetadata = false,
                                      QObject *parent = nullptr);
  ~RadioInfoReaderProxyServer() override;

  void setTargetSource(const QUrl &targetSource);
  QUrl targetSource() const;

  QUrl sourceUrl() const;
  void listen();

  void enableCapturing(bool enableCapture);

signals:
  void icyMetaDataChanged(const QVariantMap &icyMetaData);
  void loadingChanged(bool loading);
  void bitrateChanged(int bitrate);
  void bufferCaptured(const QByteArray &buffer, const QString &streamTitle);
  void mimeTypeChanged(const QMimeType &mimeType);

private slots:
  void start();
  void makeRequest(QTcpSocket *client);
  void clientConnected();
  bool validateNetworkReply(QNetworkReply *reply, QTcpSocket *client);
  void processNetworkReply(QNetworkReply *reply, IcecastParserInfo *p,
                           QTcpSocket *client);
  void forwardNetworkReply(QNetworkReply *reply, QTcpSocket *client);
  void replyReadHeaders(QNetworkReply *reply, QTcpSocket *client);

  void readIcyMetaData(IcecastParserInfo *p);
  void captureBuffer(const QByteArray &buffer, const IcecastParserInfo *p);

private:
  mutable QReadWriteLock m_lock;

  QPointer<QNetworkReply> m_reply;

  QTcpServer *m_server;
  NetworkManager *m_networkManager;

  QUrl m_targetSource;
  bool m_capturingEnabled;
  bool m_streamIcecastMetadata;
};

#endif /* !RADIOINFOREADERPROXYSERVER_H */
