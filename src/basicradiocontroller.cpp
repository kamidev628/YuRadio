#include <QAudioDevice>
#include <QAudioOutput>
#include <QMediaDevices>
#include <QMediaPlayer>

#include "basicradiocontroller.h"
#include "icecastreaderproxyserver.h"

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
      m_icecastProxy(new IcecastReaderProxyServer(this)),
      m_mediaPlayer(new QMediaPlayer(this)),
      m_mediaDevices(new QMediaDevices(this)) {
  m_mediaPlayer->setAudioOutput(new QAudioOutput(this));

  connect(m_icecastProxy, &IcecastReaderProxyServer::icyMetaDataChanged, this,
          [this](const QVariantMap &icyMetaData) {
    setStreamTitle(icyMetaData[u"StreamTitle"_s].toString());
  });
  connect(m_icecastProxy, &IcecastReaderProxyServer::loadingChanged, this,
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

QUrl BasicRadioController::icecastProxyServerUrl() {
  QUrl icecastProxyServerUrl;
  icecastProxyServerUrl.setScheme(u"http"_s);
  icecastProxyServerUrl.setHost(u"127.0.0.1"_s);
  icecastProxyServerUrl.setPort(m_icecastProxy->serverPort());
  return icecastProxyServerUrl;
}

void BasicRadioController::play() {
  QMediaPlayer::MediaStatus status = m_mediaPlayer->mediaStatus();

  if (status == QMediaPlayer::NoMedia || status == QMediaPlayer::InvalidMedia ||
      status == QMediaPlayer::EndOfMedia) {
    reconnectToIcecastProxyServer();
  }
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
  m_icecastProxy->setTargetSource(mediaItem.source);
  reconnectToIcecastProxyServer();
}

void BasicRadioController::reconnectToIcecastProxyServer() {
  m_mediaPlayer->setSource({});
  m_mediaPlayer->setSource(icecastProxyServerUrl());
}
