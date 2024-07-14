#include <QAudioDevice>
#include <QAudioOutput>
#include <QMediaDevices>
#include <QThread>

#include "icecastreader.h"
#include "radioplayer.h"

RadioPlayer::RadioPlayer(QObject *parent)
    : QMediaPlayer(parent), m_mediaDevices(new QMediaDevices(this)),
      m_icecastHint(false) {
  m_iceCastReader = std::make_unique<IcecastReader>();

  connect(this, &QMediaPlayer::mediaStatusChanged, this,
          &RadioPlayer::statusChanged);
  connect(this, &QMediaPlayer::errorOccurred, this, &RadioPlayer::handleError);
  connect(this, &QMediaPlayer::playbackStateChanged, this,
          [this](PlaybackState state) {
    switch (state) {
      case QMediaPlayer::PlayingState:
        qDebug() << "Radio start time:" << m_startTimer.elapsed();
        break;
      case QMediaPlayer::StoppedState:
      case QMediaPlayer::PausedState:
      default:
        break;
    }
  });

  connect(m_iceCastReader.get(), &IcecastReader::icyMetaDataFetched, this,
          &RadioPlayer::setIcyMetaData);
  connect(m_iceCastReader.get(), &IcecastReader::progressChanged, this,
          &RadioPlayer::setProgress);

  connect(m_mediaDevices, &QMediaDevices::audioOutputsChanged, this, [this]() {
    audioOutput()->setDevice(QMediaDevices::defaultAudioOutput());
  });

  connect(m_iceCastReader.get(), &IcecastReader::icecastStation, this,
          [this](bool isIcecast) {
    if (isIcecast) {
      qInfo() << "Icecast/Shoutcast station";
    } else {
      //m_iceCastReader->stop();
      //setIcecastHint(false);
      //playRadio();
      qInfo() << "NOT Icecast/Shoutcast station";
    }
  });
}

void RadioPlayer::playRadio() {
  if (!m_radioUrl.isValid()) {
    qWarning() << "Source url is not provided!";
    return;
  }

  if (playbackState() == PausedState) {
    play();
    return;
  }

  m_startTimer.start();
  setSourceDevice(nullptr);
  if (!m_icecastHint) {
    setSource(m_radioUrl);
    play();
    return;
  }

  stop();

  connect(m_iceCastReader.get(), &IcecastReader::audioStreamBufferReady, this,
          &RadioPlayer::icecastBufferReady,
          static_cast<Qt::ConnectionType>(Qt::SingleShotConnection |
                                          Qt::QueuedConnection));

  m_iceCastReader->start(m_radioUrl);
}

void RadioPlayer::icecastBufferReady() {
  if (!sourceDevice()) {
    setSourceDevice(m_iceCastReader->audioStreamBuffer());
  }

  play();
}

void RadioPlayer::statusChanged(QMediaPlayer::MediaStatus status) {
  qInfo() << "RadioPlayer status:" << status;

  if (status == EndOfMedia && sourceDevice()) {
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
}

QUrl RadioPlayer::radioUrl() const {
  return m_radioUrl;
}

void RadioPlayer::setRadioUrl(const QUrl &newRadioUrl) {
  if (m_radioUrl == newRadioUrl) {
    return;
  }

  stop();
  m_iceCastReader->stop();

  m_radioUrl = newRadioUrl;
  emit radioUrlChanged();
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

void RadioPlayer::toggleRadio() {
  if (isPlaying()) {
    pause();
  } else {
    playRadio();
  }
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
