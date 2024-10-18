#include "platformradiocontroller.h"

PlatformRadioController::PlatformRadioController(QObject *parent)
    : QObject(parent), m_playbackState(RadioPlayer::StoppedState),
      m_error(RadioPlayer::NoError), m_volume(1.0f), m_isLoading(false) {}

PlatformRadioController::~PlatformRadioController() = default;

RadioPlayer::PlaybackState PlatformRadioController::playbackState() const {
  return m_playbackState;
}

RadioPlayer::Error PlatformRadioController::error() const {
  return m_error;
}

void PlatformRadioController::setMediaItem(const MediaItem &mediaItem) {
  if (m_mediaItem.source != mediaItem.source) {
    setStreamTitle({});
  }

  if (m_mediaItem != mediaItem) {
    m_mediaItem = mediaItem;
    emit mediaItemChanged();
  }
}

MediaItem PlatformRadioController::mediaItem() {
  return m_mediaItem;
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

void PlatformRadioController::setVolume(float volume) {
  if (!qFuzzyCompare(m_volume, volume)) {
    m_volume = volume;
    emit volumeChanged();
  }
}

float PlatformRadioController::volume() const {
  return m_volume;
}

void PlatformRadioController::clearErrors() {
  m_error = RadioPlayer::NoError;
  m_errorString = {};
}

bool PlatformRadioController::canPlay() const {
  return m_mediaItem.source.isValid();
}

bool PlatformRadioController::canHandleMediaKeys() const {
  return false;
}

void PlatformRadioController::toggle(RadioPlayer::ToggleBehaviour behaviour) {
  if (m_playbackState != RadioPlayer::PlayingState) {
    play();
  } else if (behaviour == RadioPlayer::PlayPauseBehaviour) {
    pause();
  } else if (behaviour == RadioPlayer::PlayStopBehaviour) {
    stop();
  } else {
    Q_UNREACHABLE();
  }
}

void PlatformRadioController::setAudioStreamRecorder(
  AudioStreamRecorder *recorder) {
  if (m_recorder != recorder) {
    m_recorder = recorder;
    emit audioStreamRecorderChanged();
  }
}

AudioStreamRecorder *PlatformRadioController::audioStreamRecorder() const {
  return m_recorder;
}
