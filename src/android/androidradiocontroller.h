#ifndef ANDROIDRADIOCONTROLLER_H
#define ANDROIDRADIOCONTROLLER_H

#include <QObject>

#include "platformradiocontroller.h"

class NativeMediaController;

class AndroidRadioController : public PlatformRadioController {
  Q_OBJECT

public:
  AndroidRadioController(QObject *parent = nullptr);

  void setVolume(qreal volume) override;
  void setSource(const QUrl &source) override;
  void play() override;
  void stop() override;
  void pause() override;

private slots:
  void handlePlaybackStateChange(int playbackStateCode);
  void handleIsLoadingChange(bool isLoading);
  void handleIsPlayingChange(bool isPlaying);
  void handlePlayerError(int errorCode, const QString &message);
  void handleStreamTitleChange(const QString &streamTitle);

private:
  NativeMediaController *m_nativeController;
};

#endif /* !ANDROIDRADIOCONTROLLER_H */
