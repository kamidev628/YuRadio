#ifndef RADIOPLAYER_H
#define RADIOPLAYER_H

#include <QtQml>

class PlatformRadioController;

struct MediaItem {
  Q_GADGET
  Q_PROPERTY(QUrl source MEMBER source)
  Q_PROPERTY(QString author MEMBER author)
  Q_PROPERTY(QUrl artworkUri MEMBER artworkUri)

public:
  MediaItem() = default;

  bool operator==(const MediaItem &other) const {
    return source == other.source && author == other.author &&
           artworkUri == other.artworkUri;
  }

  bool operator!=(const MediaItem &other) const { return !(other == *this); }

  QUrl source;
  QString author;
  QUrl artworkUri;
};

class RadioPlayer : public QObject {
  Q_OBJECT
  Q_PROPERTY(
    QString streamTitle READ streamTitle NOTIFY streamTitleChanged FINAL)
  Q_PROPERTY(MediaItem mediaItem READ mediaItem WRITE setMediaItem NOTIFY
               mediaItemChanged FINAL)
  Q_PROPERTY(
    float volume READ volume WRITE setVolume NOTIFY volumeChanged FINAL)
  Q_PROPERTY(bool loading READ isLoading NOTIFY loadingChanged FINAL)
  Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
  Q_PROPERTY(
    PlaybackState playbackState READ playbackState NOTIFY playbackStateChanged)
  Q_PROPERTY(Error error READ error NOTIFY errorChanged)
  Q_PROPERTY(QString errorString READ errorString NOTIFY errorChanged)
  QML_ELEMENT

public:
  RadioPlayer(QObject *parent = nullptr);

  enum PlaybackState {
    StoppedState,
    PlayingState,
    PausedState,
  };
  Q_ENUM(PlaybackState)

  enum Error {
    NoError,
    ResourceError,
    FormatError,
    NetworkError,
    AccessDeniedError,
  };
  Q_ENUM(Error)

public slots:
  void play();
  void toggle();
  void pause();
  void stop();

  static MediaItem constructMediaItem();

  MediaItem mediaItem() const;
  void setMediaItem(const MediaItem &mediaItem);

  QString streamTitle() const;

  bool isLoading() const;

  PlaybackState playbackState() const;
  Error error() const;
  QString errorString() const;
  bool isPlaying() const;

  float volume() const;
  void setVolume(float newVolume);

signals:
  void streamTitleChanged();
  void icecastHintChanged();
  void loadingChanged();
  void playbackStateChanged();
  void errorChanged();
  void playingChanged();
  void audioOutputChanged();
  void volumeChanged();
  void mediaItemChanged();

private:
  PlatformRadioController *m_controller;
};

#endif /* !RADIOPLAYER_H */
