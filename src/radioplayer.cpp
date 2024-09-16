#include "radioplayer.h"

#ifdef Q_OS_ANDROID
#include "android/androidradiocontroller.h"
#elif defined(Q_OS_LINUX)
#include "linux/linuxradiocontroller.h"
#else
#include "basicradiocontroller.h"
#endif

#include "platformradiocontroller.h"

RadioPlayer::RadioPlayer(QObject *parent) : QObject(parent) {
#ifdef Q_OS_ANDROID
  m_controller = new AndroidRadioController(this);
#elif defined(Q_OS_LINUX)
  m_controller = new LinuxRadioController(this);
#else
  m_controller = new BasicRadioController(this);
#endif

  connect(m_controller, &PlatformRadioController::volumeChanged, this,
          &RadioPlayer::volumeChanged);
  connect(m_controller, &PlatformRadioController::mediaItemChanged, this,
          &RadioPlayer::mediaItemChanged);
  connect(m_controller, &PlatformRadioController::playbackStateChanged, this,
          &RadioPlayer::playbackStateChanged);
  connect(m_controller, &PlatformRadioController::isPlayingChanged, this,
          &RadioPlayer::playingChanged);
  connect(m_controller, &PlatformRadioController::isLoadingChanged, this,
          &RadioPlayer::loadingChanged);
  connect(m_controller, &PlatformRadioController::errorChanged, this,
          &RadioPlayer::errorChanged);
  connect(m_controller, &PlatformRadioController::streamTitleChanged, this,
          &RadioPlayer::streamTitleChanged);
}

void RadioPlayer::play() {
  m_controller->clearErrors();
  if (m_controller->canPlay()) {
    m_controller->play();
  }
}

void RadioPlayer::pause() {
  m_controller->pause();
}

void RadioPlayer::stop() {
  m_controller->stop();
}

void RadioPlayer::toggle() {
  if (isPlaying()) {
    pause();
  } else {
    play();
  }
}

RadioPlayer::PlaybackState RadioPlayer::playbackState() const {
  return m_controller->playbackState();
}

RadioPlayer::Error RadioPlayer::error() const {
  return m_controller->error();
}

QString RadioPlayer::errorString() const {
  return m_controller->errorString();
}

bool RadioPlayer::isPlaying() const {
  return m_controller->isPlaying();
}

QString RadioPlayer::streamTitle() const {
  return m_controller->streamTitle();
}

bool RadioPlayer::isLoading() const {
  return m_controller->isLoading();
}

float RadioPlayer::volume() const {
  return m_controller->volume();
}

void RadioPlayer::setVolume(float volume) {
  m_controller->setVolume(volume);
}

MediaItem RadioPlayer::mediaItem() const {
  return m_controller->mediaItem();
}

void RadioPlayer::setMediaItem(const MediaItem &mediaItem) {
  m_controller->setMediaItem(mediaItem);
}

bool RadioPlayer::canHandleMediaKeys() const {
  return m_controller->canHandleMediaKeys();
}

MediaItem RadioPlayer::constructMediaItem() {
  return {};
}
