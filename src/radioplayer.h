#ifndef RADIOPLAYER_H
#define RADIOPLAYER_H

#include <QAudioOutput>
#include <QtQml>

class PlatformRadioController;

class MediaItem : public QObject {
  Q_OBJECT
  Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
  Q_PROPERTY(QString author READ author WRITE setAuthor NOTIFY authorChanged)
  Q_PROPERTY(QUrl artworkUri READ artworkUri WRITE setArtworkUri NOTIFY
               artworkUriChanged)
  QML_ELEMENT

public:
  explicit MediaItem(QObject *parent = nullptr);

  QUrl source() const;
  void setSource(const QUrl &newSource);
  QString author() const;
  void setAuthor(const QString &newAuthor);

  QUrl artworkUri() const;
  void setArtworkUri(const QUrl &newArtworkUri);

signals:
  void sourceChanged();
  void authorChanged();
  void artworkUriChanged();

private:
  QUrl m_source;
  QString m_author;
  QUrl m_artworkUri;
};

class RadioPlayer : public QObject {
  Q_OBJECT
  Q_PROPERTY(
    QString streamTitle READ streamTitle NOTIFY streamTitleChanged FINAL)
  Q_PROPERTY(MediaItem *mediaItem READ mediaItem WRITE setMediaItem NOTIFY
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

  MediaItem *mediaItem() const;
  void setMediaItem(MediaItem *mediaItem);

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
