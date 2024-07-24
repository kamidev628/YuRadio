#include <QAudioDevice>
#include <QMediaDevices>
#include <QMediaPlayer>

#include "basicradiocontroller.h"
#include "icecastreader.h"

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
    : PlatformRadioController(parent), m_mediaPlayer(new QMediaPlayer(this)),
      m_mediaDevices(new QMediaDevices(this)) {
  m_mediaPlayer->setAudioOutput(new QAudioOutput(this));
  m_iceCastReader = std::make_unique<IcecastReader>();

  connect(m_mediaPlayer, &QMediaPlayer::mediaStatusChanged, this,
          &BasicRadioController::statusChanged);
  connect(m_mediaDevices, &QMediaDevices::audioOutputsChanged, this, [this]() {
    m_mediaPlayer->audioOutput()->setDevice(
      QMediaDevices::defaultAudioOutput());
  });
  connect(m_iceCastReader.get(), &IcecastReader::icyMetaDataChanged, this,
          [this](const QVariantMap &metaData) {
    setStreamTitle(metaData["StreamTitle"].toString());
  });
  connect(m_mediaPlayer, &QMediaPlayer::playbackStateChanged, this,
          [this](QMediaPlayer::PlaybackState state) {
    setPlaybackState(mediaPlayerStateToRadioPlayer(state));
  });
  connect(m_mediaPlayer, &QMediaPlayer::errorOccurred, this,
          [this](QMediaPlayer::Error error, const QString &message) {
    setError(mediaPlayerErrorToRadioPlayer(error), message);
  });
  connect(m_iceCastReader.get(), &IcecastReader::errorOccurred, this,
          [this](const QString &errorString) {
    setIsLoading(false);
    setError(RadioPlayer::NetworkError, errorString);
    stop();
  });
}

void BasicRadioController::play() {
  if (playbackState() == RadioPlayer::PausedState) {
    m_mediaPlayer->play();
    return;
  }

  stop();

  setIsLoading(true);
  connect(m_iceCastReader.get(), &IcecastReader::audioStreamBufferReady, this,
          &BasicRadioController::streamBufferReady,
          static_cast<Qt::ConnectionType>(Qt::SingleShotConnection |
                                          Qt::QueuedConnection));

  m_iceCastReader->start(source());
}

void BasicRadioController::statusChanged(QMediaPlayer::MediaStatus status) {
  qDebug() << "Current Status:" << status;
  if (status == QMediaPlayer::LoadingMedia) {
    setIsLoading(true);
  }

  if (status == QMediaPlayer::LoadedMedia) {
    setIsLoading(false);
  }

  if (status == QMediaPlayer::EndOfMedia && m_mediaPlayer->sourceDevice()) {
    connect(m_iceCastReader.get(), &IcecastReader::audioStreamBufferReady, this,
            &BasicRadioController::streamBufferReady,
            static_cast<Qt::ConnectionType>(Qt::SingleShotConnection |
                                            Qt::UniqueConnection |
                                            Qt::QueuedConnection));
  }
}

void BasicRadioController::streamBufferReady() {
  if (!m_mediaPlayer->sourceDevice()) {
    m_mediaPlayer->setSourceDevice(m_iceCastReader->audioStreamBuffer());
  }

  m_mediaPlayer->play();
}

void BasicRadioController::stop() {
  m_mediaPlayer->setSourceDevice(nullptr);
  m_mediaPlayer->stop();
  m_iceCastReader->stop();
}

void BasicRadioController::pause() {
  m_mediaPlayer->pause();
}

void BasicRadioController::setSource(const QUrl &source) {
  m_mediaPlayer->setSource(source);
  PlatformRadioController::setSource(source);
}
