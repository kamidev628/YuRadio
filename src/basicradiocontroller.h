#ifndef BASICRADIOCONTROLLER_H
#define BASICRADIOCONTROLLER_H

#include <QMediaPlayer>

#include "platformradiocontroller.h"

class QMediaDevices;
class IcecastReader;
class IcecastReaderProxyServer;

class BasicRadioController : public PlatformRadioController {
  Q_OBJECT

public:
  BasicRadioController(QObject *parent = nullptr);

  void play() override;
  void stop() override;
  void pause() override;

  void setVolume(float volume) override;
  void setMediaItem(MediaItem *mediaItem) override;

private:
  QUrl icecastProxyServerUrl();
  void processMediaItem(MediaItem *mediaItem);

private:
  IcecastReaderProxyServer *m_icecastProxy;
  QMediaPlayer *m_mediaPlayer;
  QMediaDevices *m_mediaDevices;
};

#endif /* !BASICRADIOCONTROLLER_H */
