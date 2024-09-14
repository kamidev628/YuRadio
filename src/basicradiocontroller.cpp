#include <QAudioDevice>
#include <QAudioOutput>
#include <QMediaDevices>
#include <QMediaPlayer>

#include "basicradiocontroller.h"
#include "radioinforeaderproxyserver.h"

using namespace Qt::StringLiterals;

static RadioPlayer::PlaybackState
mediaPlayerStateToRadioPlayer(QMediaPlayer::PlaybackState state) {
  switch (state) {
    case QMediaPlayer::StoppedState:
      return RadioPlayer::StoppedState;
    case QMediaPlayer::PlayingState:
      return RadioPlayer::PlayingState;
    case QMediaPlayer::PausedState:
      return RadioPlayer::PausedState;
    default:
      Q_UNREACHABLE();
      return RadioPlayer::StoppedState;
  }
}

static RadioPlayer::Error
mediaPlayerErrorToRadioPlayer(QMediaPlayer::Error error) {
  switch (error) {
    case QMediaPlayer::NoError:
      return RadioPlayer::NoError;
    case QMediaPlayer::ResourceError:
      return RadioPlayer::ResourceError;
    case QMediaPlayer::FormatError:
      return RadioPlayer::FormatError;
    case QMediaPlayer::NetworkError:
      return RadioPlayer::NetworkError;
    case QMediaPlayer::AccessDeniedError:
      return RadioPlayer::AccessDeniedError;
    default:
      Q_UNREACHABLE();
      return RadioPlayer::NoError;
  }
}

BasicRadioController::BasicRadioController(QObject *parent)
    : PlatformRadioController(parent),
      m_proxyServer(new RadioInfoReaderProxyServer(this)),
      m_mediaPlayer(new QMediaPlayer(this)),
      m_mediaDevices(new QMediaDevices(this)) {
  m_mediaPlayer->setAudioOutput(new QAudioOutput(this));

  connect(m_proxyServer, &RadioInfoReaderProxyServer::icyMetaDataChanged, this,
          [this](const QVariantMap &icyMetaData) {
    setStreamTitle(icyMetaData[u"StreamTitle"_s].toString());
  });
  connect(m_proxyServer, &RadioInfoReaderProxyServer::loadingChanged, this,
          [this](bool loading) { setIsLoading(loading); });
  connect(m_mediaDevices, &QMediaDevices::audioOutputsChanged, this, [this]() {
    m_mediaPlayer->audioOutput()->setDevice(
      QMediaDevices::defaultAudioOutput());
  });
  connect(m_mediaPlayer, &QMediaPlayer::playbackStateChanged, this,
          [this](QMediaPlayer::PlaybackState state) {
    setPlaybackState(mediaPlayerStateToRadioPlayer(state));
  });
  connect(m_mediaPlayer, &QMediaPlayer::errorOccurred, this,
          [this](QMediaPlayer::Error error, const QString &message) {
    setError(mediaPlayerErrorToRadioPlayer(error), message);
  });
}

void BasicRadioController::play() {
  m_mediaPlayer->play();
}

void BasicRadioController::stop() {
  m_mediaPlayer->stop();
}

void BasicRadioController::pause() {
  m_mediaPlayer->pause();
}

void BasicRadioController::setMediaItem(const MediaItem &mediaItem) {
  processMediaItem(mediaItem);

  PlatformRadioController::setMediaItem(mediaItem);
}

void BasicRadioController::setVolume(float volume) {
  m_mediaPlayer->audioOutput()->setVolume(volume);
  PlatformRadioController::setVolume(volume);
}

void BasicRadioController::processMediaItem(const MediaItem &mediaItem) {
  m_proxyServer->setTargetSource(mediaItem.source);
  m_mediaPlayer->setSource(m_proxyServer->sourceUrl());
}
