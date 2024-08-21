#ifndef ANDROIDRADIOCONTROLLER_H
#define ANDROIDRADIOCONTROLLER_H

#include <QObject>

#include "platformradiocontroller.h"

class NativeMediaController;

class AndroidRadioController : public PlatformRadioController {
  Q_OBJECT

public:
  AndroidRadioController(QObject *parent = nullptr);

  void setVolume(float volume) override;
  void setMediaItem(const MediaItem &mediaItem) override;
  void play() override;
  void stop() override;
  void pause() override;

private slots:
  void handlePlaybackStateChange(int playbackStateCode);
  void handlePlayerError(int errorCode, const QString &message);

private:
  void processMediaItem(const MediaItem &mediaItem);

private:
  NativeMediaController *m_nativeController;
};

#endif /* !ANDROIDRADIOCONTROLLER_H */
