#include "androidradiocontroller.h"

#include "nativemediacontroller.h"

AndroidRadioController::AndroidRadioController(QObject *parent)
    : PlatformRadioController(parent),
      m_nativeController(NativeMediaController::instance()) {
  connect(m_nativeController, &NativeMediaController::playbackStateChanged,
          this, &AndroidRadioController::handlePlaybackStateChange);
  connect(m_nativeController, &NativeMediaController::isPlayingChanged, this,
          &AndroidRadioController::handleIsPlayingChange);
  connect(m_nativeController, &NativeMediaController::isLoadingChanged, this,
          &AndroidRadioController::handleIsLoadingChange);
  connect(m_nativeController, &NativeMediaController::playerErrorChanged, this,
          &AndroidRadioController::handlePlayerError);
  connect(m_nativeController, &NativeMediaController::streamTitleChanged, this,
          &AndroidRadioController::handleStreamTitleChange);
}

void AndroidRadioController::play() {
  m_nativeController->play();
}

void AndroidRadioController::stop() {
  m_nativeController->stop();
}

void AndroidRadioController::pause() {
  m_nativeController->pause();
}

void AndroidRadioController::setSource(const QUrl &source) {
  if (source.isValid()) {
    m_nativeController->setSource(source);
  }
  PlatformRadioController::setSource(source);
}

void AndroidRadioController::handlePlaybackStateChange(int playbackStateCode) {
  Q_UNUSED(playbackStateCode);

  switch (playbackStateCode) {
    case NativeMediaController::PlayingState:
      setPlaybackState(RadioPlayer::PlayingState);
      break;
    case NativeMediaController::PausedState:
      setPlaybackState(RadioPlayer::PausedState);
      break;
    case NativeMediaController::StoppedState:
      setPlaybackState(RadioPlayer::StoppedState);
      break;
  }
}

static QString errorMessageForCode(int errorCode) {
  switch (errorCode) {
    case NativeMediaController::ERROR_CODE_IO_UNSPECIFIED:
    case NativeMediaController::ERROR_CODE_UNSPECIFIED:
      return "Unknown Error";
    case NativeMediaController::ERROR_CODE_REMOTE_ERROR:
      return "Internal Server Error";
    case NativeMediaController::ERROR_CODE_BEHIND_LIVE_WINDOW:
      return "Playback Behind Live Window";
    case NativeMediaController::ERROR_CODE_TIMEOUT:
      return "Connection Timeout";
    case NativeMediaController::ERROR_CODE_FAILED_RUNTIME_CHECK:
      return "Runtime Check Failed";
    case NativeMediaController::ERROR_CODE_IO_NO_PERMISSION:
      return "Permission denied";
    case NativeMediaController::ERROR_CODE_IO_NETWORK_CONNECTION_FAILED:
      return "Network Connection Failed";
    case NativeMediaController::ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT:
      return "Network Connection Timeout";
    case NativeMediaController::ERROR_CODE_IO_INVALID_HTTP_CONTENT_TYPE:
      return "Invalid HTTP Content Type";
    case NativeMediaController::ERROR_CODE_IO_BAD_HTTP_STATUS:
      return "Bad HTTP Status";
    case NativeMediaController::ERROR_CODE_IO_FILE_NOT_FOUND:
      return "File Not Found";
    case NativeMediaController::ERROR_CODE_IO_READ_POSITION_OUT_OF_RANGE:
      return "Read Position Out Of Range";
    case NativeMediaController::ERROR_CODE_IO_CLEARTEXT_NOT_PERMITTED:
      return "HTTP Traffic Not Supported";
    case NativeMediaController::ERROR_CODE_PARSING_CONTAINER_MALFORMED:
      return "Parsing Container Malformed";
    case NativeMediaController::ERROR_CODE_PARSING_MANIFEST_MALFORMED:
      return "Parsing Manifest Malformed";
    case NativeMediaController::ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED:
      return "Parsing Container Unsupported";
    case NativeMediaController::ERROR_CODE_PARSING_MANIFEST_UNSUPPORTED:
      return "Parsing Manifest Unsupported";

    case NativeMediaController::ERROR_CODE_DECODER_INIT_FAILED:
      return "Decoder Init Failed";
    case NativeMediaController::ERROR_CODE_DECODER_QUERY_FAILED:
      return "Decoder Query Failed";
    case NativeMediaController::ERROR_CODE_DECODING_FAILED:
      return "Decoder Decoding Failed";
    case NativeMediaController::ERROR_CODE_DECODING_FORMAT_EXCEEDS_CAPABILITIES:
      return "Decoder Format Exceeds Capabilities";
    case NativeMediaController::ERROR_CODE_DECODING_FORMAT_UNSUPPORTED:
      return "Decoder Format Unsupported";
    default:
      return "Unknown";
  }
}

void AndroidRadioController::handlePlayerError(int errorCode,
                                               const QString &message) {
  RadioPlayer::Error playerError = RadioPlayer::ResourceError;
  QString errorMessage = errorMessageForCode(errorCode);

  switch (errorCode) {
    case NativeMediaController::ERROR_CODE_UNSPECIFIED:
    case NativeMediaController::ERROR_CODE_REMOTE_ERROR:
    case NativeMediaController::ERROR_CODE_BEHIND_LIVE_WINDOW: {
      playerError = RadioPlayer::ResourceError;
      break;
    }

    case NativeMediaController::ERROR_CODE_TIMEOUT:
    case NativeMediaController::ERROR_CODE_FAILED_RUNTIME_CHECK: {
      playerError = RadioPlayer::ResourceError;
      break;
    }

    case NativeMediaController::ERROR_CODE_IO_NO_PERMISSION: {
      playerError = RadioPlayer::AccessDeniedError;
      break;
    }

    case NativeMediaController::ERROR_CODE_IO_UNSPECIFIED:
    case NativeMediaController::ERROR_CODE_IO_NETWORK_CONNECTION_FAILED:
    case NativeMediaController::ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT:
    case NativeMediaController::ERROR_CODE_IO_INVALID_HTTP_CONTENT_TYPE:
    case NativeMediaController::ERROR_CODE_IO_BAD_HTTP_STATUS:
    case NativeMediaController::ERROR_CODE_IO_FILE_NOT_FOUND:
    case NativeMediaController::ERROR_CODE_IO_READ_POSITION_OUT_OF_RANGE:
    case NativeMediaController::ERROR_CODE_IO_CLEARTEXT_NOT_PERMITTED: {
      playerError = RadioPlayer::NetworkError;
      break;
    }

    case NativeMediaController::ERROR_CODE_PARSING_CONTAINER_MALFORMED:
    case NativeMediaController::ERROR_CODE_PARSING_MANIFEST_MALFORMED:
    case NativeMediaController::ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED:
    case NativeMediaController::ERROR_CODE_PARSING_MANIFEST_UNSUPPORTED: {
      playerError = RadioPlayer::ResourceError;
      break;
    }

    case NativeMediaController::ERROR_CODE_DECODER_INIT_FAILED:
    case NativeMediaController::ERROR_CODE_DECODER_QUERY_FAILED:
    case NativeMediaController::ERROR_CODE_DECODING_FAILED:
    case NativeMediaController::ERROR_CODE_DECODING_FORMAT_EXCEEDS_CAPABILITIES:
    case NativeMediaController::ERROR_CODE_DECODING_FORMAT_UNSUPPORTED: {
      playerError = RadioPlayer::FormatError;
      break;
    }
  }

  setError(playerError, errorMessage);
}

void AndroidRadioController::handleIsPlayingChange(bool isPlaying) {
  Q_UNUSED(isPlaying);
}

void AndroidRadioController::handleStreamTitleChange(
  const QString &streamTitle) {
  setStreamTitle(streamTitle);
}

void AndroidRadioController::handleIsLoadingChange(bool isLoading) {
  setIsLoading(isLoading);
}
