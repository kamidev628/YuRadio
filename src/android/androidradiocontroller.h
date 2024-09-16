#ifndef ANDROIDRADIOCONTROLLER_H
#define ANDROIDRADIOCONTROLLER_H

#include <QObject>

#include "platformradiocontroller.h"

class NativeMediaController;
class AndroidMediaSessionImageProvider;

class AndroidRadioController : public PlatformRadioController {
  Q_OBJECT

public:
  AndroidRadioController(QObject *parent = nullptr);

  void setVolume(float volume) override;
  void setMediaItem(const MediaItem &mediaItem) override;
  void play() override;
  void stop() override;
  void pause() override;

  bool canHandleMediaKeys() const override;

private slots:
  void playbackStateChanged(int playbackStateCode);
  void playerError(int errorCode, const QString &message);

private:
  void processMediaItem(const MediaItem &mediaItem);

private:
  NativeMediaController *m_nativeController;
  AndroidMediaSessionImageProvider *m_mediaSessionImageProvider;
};

#endif /* !ANDROIDRADIOCONTROLLER_H */
