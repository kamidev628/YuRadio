#ifndef NATIVEMEDIACONTROLLER_H
#define NATIVEMEDIACONTROLLER_H

#include <QJniObject>
#include <QObject>
#include <QUrl>

class NativeMediaController : public QObject {
  Q_OBJECT

public:
  enum PlaybackError {
    ERROR_CODE_UNSPECIFIED = 1000,
    ERROR_CODE_REMOTE_ERROR = 1001,
    ERROR_CODE_BEHIND_LIVE_WINDOW = 1002,

    ERROR_CODE_TIMEOUT = 1003,
    ERROR_CODE_FAILED_RUNTIME_CHECK = 1004,

    ERROR_CODE_IO_UNSPECIFIED = 2000,
    ERROR_CODE_IO_NETWORK_CONNECTION_FAILED = 2001,
    ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT = 2002,
    ERROR_CODE_IO_INVALID_HTTP_CONTENT_TYPE = 2003,
    ERROR_CODE_IO_BAD_HTTP_STATUS = 2004,
    ERROR_CODE_IO_FILE_NOT_FOUND = 2005,
    ERROR_CODE_IO_NO_PERMISSION = 2006,
    ERROR_CODE_IO_CLEARTEXT_NOT_PERMITTED = 2007,

    ERROR_CODE_IO_READ_POSITION_OUT_OF_RANGE = 2008,
    ERROR_CODE_PARSING_CONTAINER_MALFORMED = 3001,

    ERROR_CODE_PARSING_MANIFEST_MALFORMED = 3002,
    ERROR_CODE_PARSING_CONTAINER_UNSUPPORTED = 3003,
    ERROR_CODE_PARSING_MANIFEST_UNSUPPORTED = 3004,

    ERROR_CODE_DECODER_INIT_FAILED = 4001,
    ERROR_CODE_DECODER_QUERY_FAILED = 4002,
    ERROR_CODE_DECODING_FAILED = 4003,

    ERROR_CODE_DECODING_FORMAT_EXCEEDS_CAPABILITIES = 4004,
    ERROR_CODE_DECODING_FORMAT_UNSUPPORTED = 4005,
  };

  Q_ENUM(PlaybackError);

  enum PlaybackState {
    PlayingState = 0,
    StoppedState,
    PausedState,
  };

  Q_ENUM(PlaybackState);

  static NativeMediaController *instance();
  static void registerNativeMethods();

  void play();
  void stop();
  void pause();
  void setSource(const QUrl &url);

  void setAuthor(const QString &author);
  void setArtworkUri(const QUrl &url);

  void setVolume(float volume);

signals:
  void playbackStateChanged(int playbackStateCode);
  void isPlayingChanged(bool isPlaying);
  void isLoadingChanged(bool isLoading);
  void streamTitleChanged(const QString &title);
  void playerErrorChanged(int errorCode, const QString &message);

private:
  NativeMediaController(QObject *parent = nullptr);
  Q_DISABLE_COPY(NativeMediaController);

private:
  QJniObject m_controller;
};

#endif /* !NATIVEMEDIACONTROLLER_H */
