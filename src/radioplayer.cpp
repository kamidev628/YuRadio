#include <QAudioDevice>
#include <QAudioOutput>
#include <QMediaDevices>
#include <QThread>

#include "icecastreader.h"
#include "radioplayer.h"

RadioPlayer::RadioPlayer(QObject *parent)
    : QObject(parent), m_mediaDevices(new QMediaDevices(this)),
      m_player(new QMediaPlayer(this)), m_progress(1), m_icecastHint(false) {

  m_iceCastReader = std::make_unique<IcecastReader>();

  connect(m_player, &QMediaPlayer::playbackStateChanged, this,
          &RadioPlayer::playbackStateChanged);
  connect(m_player, &QMediaPlayer::mediaStatusChanged, this,
          &RadioPlayer::statusChanged);
  connect(m_player, &QMediaPlayer::errorOccurred, this,
          &RadioPlayer::handleError);
  connect(m_player, &QMediaPlayer::playingChanged, this,
          &RadioPlayer::playingChanged);
  connect(m_player, &QMediaPlayer::audioOutputChanged, this,
          &RadioPlayer::audioOutputChanged);
  connect(m_player, &QMediaPlayer::playbackStateChanged, this,
          [this](QMediaPlayer::PlaybackState state) {
    switch (state) {
      case QMediaPlayer::PlayingState:
        qDebug() << "Radio start time:" << m_startTimer.elapsed();
        setProgress(1);
        break;
      case QMediaPlayer::StoppedState:
        m_iceCastReader->stop();
        break;
      case QMediaPlayer::PausedState:
      default:
        break;
    }

    emit playbackStateChanged();
  });

  connect(m_iceCastReader.get(), &IcecastReader::icyMetaDataChanged, this,
          &RadioPlayer::setIcyMetaData);
  connect(m_iceCastReader.get(), &IcecastReader::progressChanged, this,
          &RadioPlayer::setProgress);
  connect(m_iceCastReader.get(), &IcecastReader::errorOccurred, this,
          [this](const QString &errorString) {
    m_error = NetworkError;
    m_errorString = errorString;

    stop();

    emit errorChanged();
  });

  connect(m_mediaDevices, &QMediaDevices::audioOutputsChanged, this, [this]() {
    m_player->audioOutput()->setDevice(QMediaDevices::defaultAudioOutput());
  });

  connect(m_iceCastReader.get(), &IcecastReader::icecastStation, this,
          [](bool isIcecast) {
    if (isIcecast) {
      qInfo() << "Icecast/Shoutcast station";
    } else {
      qInfo() << "NOT Icecast/Shoutcast station";
    }
  });
}

void RadioPlayer::play() {
  if (!m_radioUrl.isValid()) {
    qWarning() << "Source url is not provided!";
    return;
  }

  if (playbackState() == PausedState) {
    m_player->play();
    return;
  }

  m_startTimer.start();

  m_player->setSourceDevice(nullptr);
  m_player->stop();
  setProgress(0);

  if (!m_icecastHint) {
    m_player->setSource(m_radioUrl);
    m_player->play();
    return;
  }

  connect(m_iceCastReader.get(), &IcecastReader::audioStreamBufferReady, this,
          &RadioPlayer::icecastBufferReady,
          static_cast<Qt::ConnectionType>(Qt::SingleShotConnection |
                                          Qt::QueuedConnection));

  m_iceCastReader->start(m_radioUrl);
}

void RadioPlayer::pause() {
  m_player->pause();
}

void RadioPlayer::stop() {
  setProgress(1);
  m_player->stop();
}

void RadioPlayer::toggle() {
  if (m_player->isPlaying()) {
    pause();
  } else {
    play();
  }
}

void RadioPlayer::icecastBufferReady() {
  if (!m_player->sourceDevice()) {
    m_player->setSourceDevice(m_iceCastReader->audioStreamBuffer());
  }

  m_player->play();
}

void RadioPlayer::statusChanged(QMediaPlayer::MediaStatus status) {
  qInfo() << "RadioPlayer status:" << status;

  if (status == QMediaPlayer::EndOfMedia && m_player->sourceDevice()) {
    connect(m_iceCastReader.get(), &IcecastReader::audioStreamBufferReady, this,
            &RadioPlayer::icecastBufferReady,
            static_cast<Qt::ConnectionType>(Qt::SingleShotConnection |
                                            Qt::UniqueConnection |
                                            Qt::QueuedConnection));
  }
}

void RadioPlayer::handleError(QMediaPlayer::Error error,
                              const QString &errorString) {
  qWarning() << error << errorString;

  m_error = static_cast<Error>(error);
  m_errorString = errorString;

  emit errorChanged();
}

QVariantMap RadioPlayer::icyMetaData() const {
  return m_icyMetaData;
}

void RadioPlayer::setIcyMetaData(const QVariantMap &metaData) {
  if (m_icyMetaData == metaData) {
    return;
  }

  m_icyMetaData = metaData;
  emit icyMetaDataChanged();
}

QUrl RadioPlayer::source() const {
  return m_radioUrl;
}

void RadioPlayer::setSource(const QUrl &newRadioUrl) {
  if (m_radioUrl == newRadioUrl) {
    return;
  }

  m_player->stop();
  setIcyMetaData({});

  m_radioUrl = newRadioUrl;
  emit sourceChanged();
}

bool RadioPlayer::icecastHint() const {
  return m_icecastHint;
}

void RadioPlayer::setIcecastHint(bool newIcecastHint) {
  if (m_icecastHint == newIcecastHint) {
    return;
  }
  m_icecastHint = newIcecastHint;
  emit icecastHintChanged();
}

qreal RadioPlayer::progress() const {
  return m_progress;
}

void RadioPlayer::setProgress(qreal newProgress) {
  if (qFuzzyCompare(m_progress, newProgress)) {
    return;
  }

  m_progress = newProgress;
  emit progressChanged();
}

RadioPlayer::PlaybackState RadioPlayer::playbackState() const {
  return static_cast<RadioPlayer::PlaybackState>(m_player->playbackState());
}

RadioPlayer::Error RadioPlayer::error() const {
  return m_error;
}

QString RadioPlayer::errorString() const {
  return m_errorString;
}

bool RadioPlayer::isPlaying() const {
  return m_player->isPlaying();
}

QAudioOutput *RadioPlayer::audioOutput() const {
  return m_audioOutput;
}

void RadioPlayer::setAudioOutput(QAudioOutput *newAudioOutput) {
  m_player->setAudioOutput(newAudioOutput);
}
