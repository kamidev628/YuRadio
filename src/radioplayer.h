#ifndef RADIOPLAYER_H
#define RADIOPLAYER_H

#include <QAudioOutput>
#include <QMediaPlayer>
#include <QtQml>

#include "icecastreader.h"

class QMediaDevices;
class QMediaPlayer;
class QThread;

class RadioPlayer : public QObject {
  Q_OBJECT
  Q_PROPERTY(
    QVariantMap icyMetaData READ icyMetaData NOTIFY icyMetaDataChanged FINAL)
  Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged FINAL)
  Q_PROPERTY(bool icecastHint READ icecastHint WRITE setIcecastHint NOTIFY
               icecastHintChanged FINAL)
  Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged FINAL)
  Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
  Q_PROPERTY(
    PlaybackState playbackState READ playbackState NOTIFY playbackStateChanged)
  Q_PROPERTY(Error error READ error NOTIFY errorChanged)
  Q_PROPERTY(QString errorString READ errorString NOTIFY errorChanged)
  Q_PROPERTY(QAudioOutput *audioOutput READ audioOutput WRITE setAudioOutput
               NOTIFY audioOutputChanged)
  QML_ELEMENT

public:
  RadioPlayer(QObject *parent = nullptr);

  enum PlaybackState { StoppedState, PlayingState, PausedState };
  Q_ENUM(PlaybackState)

  enum Error {
    NoError,
    ResourceError,
    FormatError,
    NetworkError,
    AccessDeniedError
  };
  Q_ENUM(Error)

  Q_INVOKABLE void play();
  Q_INVOKABLE void toggle();
  Q_INVOKABLE void pause();
  Q_INVOKABLE void stop();

  QVariantMap icyMetaData() const;

  QUrl source() const;
  void setSource(const QUrl &newRadioUrl);

  bool icecastHint() const;
  void setIcecastHint(bool newIcecastHint);

  qreal progress() const;

  PlaybackState playbackState() const;
  Error error() const;
  QString errorString() const;
  bool isPlaying() const;

  QAudioOutput *audioOutput() const;
  void setAudioOutput(QAudioOutput *newAudioOutput);

signals:
  void icyMetaDataChanged();
  void sourceChanged();
  void icecastHintChanged();
  void progressChanged();
  void playbackStateChanged();
  void errorChanged();
  void playingChanged();
  void audioOutputChanged();

protected:
  void setIcyMetaData(const QVariantMap &metaData);
  void setProgress(qreal newProgress);

private slots:
  void icecastBufferReady();

  void statusChanged(QMediaPlayer::MediaStatus status);
  void handleError(QMediaPlayer::Error error, const QString &errorString);

private:
  std::unique_ptr<IcecastReader> m_iceCastReader;
  QMediaDevices *m_mediaDevices;
  QMediaPlayer *m_player;

  QUrl m_radioUrl;

  QVariantMap m_icyMetaData;
  Error m_error;
  QString m_errorString;

  QElapsedTimer m_startTimer;
  qreal m_progress;

  bool m_icecastHint;
  QAudioOutput *m_audioOutput = nullptr;
};

#endif /* !RADIOPLAYER_H */
