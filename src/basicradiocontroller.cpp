#include <QAudioDevice>
#include <QMediaDevices>
#include <QMediaPlayer>

#include "basicradiocontroller.h"
#include "icecastreaderproxyserver.h"

static RadioPlayer::PlaybackState
mediaPlayerStateToRadioPlayer(QMediaPlayer::PlaybackState state) {
  switch (state) {
    case QMediaPlayer::StoppedState:
      return RadioPlayer::StoppedState;
    case QMediaPlayer::PlayingState:
      return RadioPlayer::PlayingState;
    case QMediaPlayer::PausedState:
      return RadioPlayer::PausedState;
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
    setStreamTitle(icyMetaData["StreamTitle"].toString());
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
  icecastProxyServerUrl.setScheme("http");
  icecastProxyServerUrl.setHost("127.0.0.1");
  icecastProxyServerUrl.setPort(m_icecastProxy->serverPort());
  return icecastProxyServerUrl;
}

void BasicRadioController::play() {
  if (m_mediaPlayer->playbackState() == QMediaPlayer::StoppedState) {
    m_mediaPlayer->setSource({});
    m_mediaPlayer->setSource(icecastProxyServerUrl());
  }
  m_mediaPlayer->play();
}

void BasicRadioController::stop() {
  m_mediaPlayer->stop();
}

void BasicRadioController::pause() {
  m_mediaPlayer->pause();
}

void BasicRadioController::setSource(const QUrl &source) {
  if (source.isValid()) {
    m_icecastProxy->setTargetSource(source);

    m_mediaPlayer->setSource({});
    m_mediaPlayer->setSource(icecastProxyServerUrl());
  }

  PlatformRadioController::setSource(source);
}
