#ifndef ANDROIDRADIOCONTROLLER_H
#define ANDROIDRADIOCONTROLLER_H

#include <QObject>

#include "platformradiocontroller.h"

class NativeMediaController;
class AndroidMediaSessionImageProvider;
class RadioInfoReaderProxyServer;

class AndroidRadioController : public PlatformRadioController {
  Q_OBJECT

public:
  explicit AndroidRadioController(QObject *parent = nullptr);
  ~AndroidRadioController() override;

  void setVolume(float volume) override;
  void setMediaItem(const MediaItem &mediaItem) override;
  void play() override;
  void stop() override;
  void pause() override;

  bool canHandleMediaKeys() const override;

private slots:
  void playbackStateChanged(int playbackStateCode);
  void playerError(int errorCode, const QString &message);
  void onAudioStreamRecorderChanged();

private:
  void processMediaItem(const MediaItem &mediaItem);

private:
  NativeMediaController *m_nativeController;
  AndroidMediaSessionImageProvider *m_mediaSessionImageProvider;

  RadioInfoReaderProxyServer *m_proxyServer;
  QThread m_proxyServerThread;
};

#endif /* !ANDROIDRADIOCONTROLLER_H */
