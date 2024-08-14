#ifndef PLATFORMRADIOCONTROLLER_H
#define PLATFORMRADIOCONTROLLER_H

#include "radioplayer.h"

class PlatformRadioController : public QObject {
  Q_OBJECT

public:
  PlatformRadioController(QObject *parent = nullptr);
  ~PlatformRadioController() override;
  virtual RadioPlayer::PlaybackState playbackState() const;
  virtual RadioPlayer::Error error() const;
  virtual QString errorString() const;
  virtual QString streamTitle() const;

  virtual void setMediaItem(MediaItem *mediaItem);
  virtual MediaItem *mediaItem();

  virtual void play() = 0;
  virtual void pause() = 0;
  virtual void stop() = 0;

  virtual void setVolume(float volume);
  virtual float volume() const;

  virtual bool isPlaying() const;
  virtual bool isLoading() const;
  void clearErrors();

signals:
  void mediaItemChanged();
  void playbackStateChanged();
  void errorChanged();
  void isPlayingChanged();
  void isLoadingChanged();
  void streamTitleChanged();
  void volumeChanged();

protected:
  void setError(RadioPlayer::Error error, const QString &errorString);
  void setPlaybackState(RadioPlayer::PlaybackState state);
  void setStreamTitle(const QString &streamTitle);
  void setIsLoading(bool isLoading);

protected:
  RadioPlayer::PlaybackState m_playbackState;
  RadioPlayer::Error m_error;
  MediaItem *m_mediaItem = nullptr;
  QString m_errorString;
  QString m_streamTitle;
  float m_volume;
  QUrl m_source;
  bool m_isLoading;
};

#endif /* !PLATFORMRADIOCONTROLLER_H */
