#ifndef RADIOPLAYER_H
#define RADIOPLAYER_H

#include <QAudioOutput>
#include <QtQml>

class PlatformRadioController;

class RadioPlayer : public QObject {
  Q_OBJECT
  Q_PROPERTY(
    QString streamTitle READ streamTitle NOTIFY streamTitleChanged FINAL)
  Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged FINAL)
  Q_PROPERTY(
    qreal volume READ volume WRITE setVolume NOTIFY volumeChanged FINAL)
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

  QString streamTitle() const;

  QUrl source() const;
  void setSource(const QUrl &newRadioUrl);

  bool isLoading() const;

  PlaybackState playbackState() const;
  Error error() const;
  QString errorString() const;
  bool isPlaying() const;

  qreal volume() const;
  void setVolume(qreal newVolume);

signals:
  void streamTitleChanged();
  void sourceChanged();
  void icecastHintChanged();
  void loadingChanged();
  void playbackStateChanged();
  void errorChanged();
  void playingChanged();
  void audioOutputChanged();
  void volumeChanged();

private:
  PlatformRadioController *m_controller;
};

#endif /* !RADIOPLAYER_H */
