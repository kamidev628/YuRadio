#include <QLoggingCategory>
Q_LOGGING_CATEGORY(basicRadioControllerLog, "YuRadio.BasicRadioController")

#include <QAudioDevice>
#include <QAudioOutput>
#include <QMediaDevices>
#include <QMediaPlayer>
#include <QNetworkInformation>

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
  }
  Q_UNREACHABLE();
  return RadioPlayer::StoppedState;
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
  Q_UNREACHABLE();
  return RadioPlayer::NoError;
}

BasicRadioController::BasicRadioController(QObject *parent)
    : PlatformRadioController(parent),
      m_proxyServer(new RadioInfoReaderProxyServer),
      m_mediaPlayer(new QMediaPlayer(this)),
      m_mediaDevices(new QMediaDevices(this)) {
  connect(&m_proxyServerThread, &QThread::started, m_proxyServer,
          &RadioInfoReaderProxyServer::listen);
  connect(&m_proxyServerThread, &QThread::finished, m_proxyServer,
          &QObject::deleteLater);

  auto *audioOutput = new QAudioOutput(this);
  m_mediaPlayer->setAudioOutput(audioOutput);
  connect(audioOutput, &QAudioOutput::volumeChanged, this,
          [this](float volume) { PlatformRadioController::setVolume(volume); });

  auto *networkInformation = QNetworkInformation::instance();
  connect(networkInformation, &QNetworkInformation::reachabilityChanged, this,
          [this](QNetworkInformation::Reachability reachability) {
    if (reachability == QNetworkInformation::Reachability::Online &&
        m_mediaPlayer->mediaStatus() == QMediaPlayer::EndOfMedia) {
      play();
    }
  });
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
  connect(m_mediaPlayer, &QMediaPlayer::mediaStatusChanged, this,
          &BasicRadioController::mediaStatusChanged);
  connect(m_mediaPlayer, &QMediaPlayer::playbackStateChanged, this,
          [this](QMediaPlayer::PlaybackState state) {
    qCDebug(basicRadioControllerLog) << "Playback State:" << state;
    setPlaybackState(mediaPlayerStateToRadioPlayer(state));
  });
  connect(m_mediaPlayer, &QMediaPlayer::errorOccurred, this,
          [this](QMediaPlayer::Error error, const QString &message) {
    qCWarning(basicRadioControllerLog) << error << message;
    setError(mediaPlayerErrorToRadioPlayer(error), message);
  });

  m_proxyServerThread.setObjectName("RadioInfoReaderProxyServer Thread"_L1);
  m_proxyServer->moveToThread(&m_proxyServerThread);
  m_proxyServerThread.start();
}

BasicRadioController::~BasicRadioController() {
  m_proxyServerThread.quit();
  m_proxyServerThread.wait();
}

void BasicRadioController::play() {
  if (m_mediaItem.source.isValid()) {
    m_mediaPlayer->setSource(m_proxyServer->sourceUrl());
  }
  m_mediaPlayer->play();
}

void BasicRadioController::stop() {
  m_mediaPlayer->stop();
  m_mediaPlayer->setSource({});
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
}

void BasicRadioController::processMediaItem(const MediaItem &mediaItem) {
  m_proxyServer->setTargetSource(mediaItem.source);
  m_mediaPlayer->setSource(m_proxyServer->sourceUrl());
}

void BasicRadioController::mediaStatusChanged(
  QMediaPlayer::MediaStatus status) {
  qCDebug(basicRadioControllerLog) << "Media Status:" << status;

  if (status == QMediaPlayer::EndOfMedia) {
    m_mediaPlayer->play();
  }
}
