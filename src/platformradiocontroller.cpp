#include "platformradiocontroller.h"

PlatformRadioController::PlatformRadioController(QObject *parent)
    : QObject(parent), m_isLoading(false), m_error(RadioPlayer::NoError),
      m_playbackState(RadioPlayer::StoppedState) {}

PlatformRadioController::~PlatformRadioController() = default;

RadioPlayer::PlaybackState PlatformRadioController::playbackState() const {
  return m_playbackState;
}

RadioPlayer::Error PlatformRadioController::error() const {
  return m_error;
}

void PlatformRadioController::setSource(const QUrl &source) {
  if (m_source != source) {
    m_source = source;
    emit sourceChanged();
  }
}

QUrl PlatformRadioController::source() const {
  return m_source;
}

void PlatformRadioController::setError(RadioPlayer::Error error,
                                       const QString &errorString) {
  m_error = error;
  m_errorString = errorString;
  emit errorChanged();
}

void PlatformRadioController::setPlaybackState(
  RadioPlayer::PlaybackState state) {

  if (m_playbackState != state) {
    RadioPlayer::PlaybackState stateBefore = m_playbackState;

    m_playbackState = state;
    emit playbackStateChanged();

    if (state == RadioPlayer::PlayingState ||
        stateBefore == RadioPlayer::PlayingState) {
      emit isPlayingChanged();
    }
  }
}

void PlatformRadioController::setStreamTitle(const QString &streamTitle) {
  if (m_streamTitle != streamTitle) {
    m_streamTitle = streamTitle;
    emit streamTitleChanged();
  }
}

QString PlatformRadioController::streamTitle() const {
  return m_streamTitle;
}

QString PlatformRadioController::errorString() const {
  return m_errorString;
}

bool PlatformRadioController::isPlaying() const {
  return m_playbackState == RadioPlayer::PlayingState;
}

void PlatformRadioController::setIsLoading(bool isLoading) {
  if (m_isLoading != isLoading) {
    m_isLoading = isLoading;
    emit isLoadingChanged();
  }
}

bool PlatformRadioController::isLoading() const {
  return m_isLoading;
}
