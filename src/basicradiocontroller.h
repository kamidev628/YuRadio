#ifndef BASICRADIOCONTROLLER_H
#define BASICRADIOCONTROLLER_H

#include <QMediaPlayer>

#include "platformradiocontroller.h"

class QMediaDevices;
class RadioInfoReaderProxyServer;

class BasicRadioController : public PlatformRadioController {
  Q_OBJECT

public:
  BasicRadioController(QObject *parent = nullptr);

  void play() override;
  void stop() override;
  void pause() override;

  void setVolume(float volume) override;
  void setMediaItem(const MediaItem &mediaItem) override;

private slots:
  void mediaStatusChanged(QMediaPlayer::MediaStatus status);

private:
  void processMediaItem(const MediaItem &mediaItem);

protected:
  RadioInfoReaderProxyServer *m_proxyServer;
  QMediaPlayer *m_mediaPlayer;
  QMediaDevices *m_mediaDevices;
  int m_numberRetries;
};

#endif /* !BASICRADIOCONTROLLER_H */
