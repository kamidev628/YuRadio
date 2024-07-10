#ifndef ICECASTREADER_H
#define ICECASTREADER_H

#include <QMediaDevices>
#include <QNetworkReply>

#include <QPointer>
#include <QThread>

#include "circularbuffer.h"
#include "network.h"

class NetworkManager;
class QMediaPlayer;

class IcecastReader : public QObject {
  Q_OBJECT

public:
  explicit IcecastReader(QObject *parent = nullptr);
  ~IcecastReader() override;

  QIODevice *audioStreamBuffer();
  qint64 minimumBufferSize() const;

signals:
  void icecastStation(bool isIcecast);
  void icyMetaDataFetched(const QVariantMap &metaData);
  void audioStreamBufferReady();
  void stopped();

public slots:
  void start(const QUrl &url);
  void stop();

private slots:
  void reset();
  void startImpl(const QUrl &url);
  void stopImpl();

  void replyReadyRead();
  void readHeaders();
  void cleanup();

private:
  bool writeBuffer(qint64 bytes);
  void measureDownloadTime();
  void metaDataRead();

private:
  std::unique_ptr<QThread> m_thread;

  QByteArray m_icyMetaDataBuffer;
  QVariantMap m_icyMetaData;
  int m_icyMetaInt;
  int m_icyMetaLeft;

  CircularBuffer m_buffer;

  NetworkManager *m_networkManager;
  ReplyPointer m_reply;

  QUrl m_stationUrl;

  QElapsedTimer m_downloadTimer;
  qreal m_averageSpeed = 0;

  int m_bitrate;
  qint64 m_bytesRead;
  qint64 m_minimumBufferSize;
};

#endif /* !ICECASTREADER_H */
