#include <QLoggingCategory>
Q_LOGGING_CATEGORY(audioStreamRecorderLog, "YuRadio.AudioStreamRecorder")

#ifdef Q_OS_ANDROID
#include <QtCore/private/qandroidextras_p.h>
#endif /* Q_OS_ANDROID */

#include <QFileInfo>

#include "audiostreamrecorder.h"

using namespace Qt::StringLiterals;

AudioStreamRecorder::AudioStreamRecorder(QObject *parent)
    : QObject(parent), m_file(new QFile(this)) {
  QString musicLocation =
    QStandardPaths::writableLocation(QStandardPaths::MusicLocation) +
    u"/YuRadio"_s;

  /* Ensure music location path exists */
  QDir().mkpath(musicLocation);
  m_outputLocation = QUrl::fromLocalFile(musicLocation);
  qCDebug(audioStreamRecorderLog)
    << "Default music location:" << m_outputLocation;

  m_recordingPolicy = NoRecordingPolicy;
  m_recordingNamePolicy = StationDateTime;
}

AudioStreamRecorder::~AudioStreamRecorder() {
  stop();
}

QUrl AudioStreamRecorder::outputLocation() const {
  return m_outputLocation;
}

void AudioStreamRecorder::setOutputLocation(const QUrl &outputLocation) {
  if (m_outputLocation != outputLocation) {
    m_outputLocation = outputLocation;
    emit outputLocationChanged();
  }
}

bool AudioStreamRecorder::recording() const {
  return m_recording;
}

void AudioStreamRecorder::record() {
  qCDebug(audioStreamRecorderLog) << "Record";

#ifdef Q_OS_ANDROID
  static std::once_flag checkPermissionFlag;
  std::call_once(checkPermissionFlag, []() {
    QList<QString> permissions = {
      u"android.permission.WRITE_EXTERNAL_STORAGE"_s,
      u"android.permission.READ_EXTERNAL_STORAGE"_s,
      u"android.permission.READ_MEDIA_AUDIO"_s};

    for (const auto &permission : permissions) {
      if (QtAndroidPrivate::checkPermission(permission).result() !=
          QtAndroidPrivate::Authorized) {
        auto result = QtAndroidPrivate::requestPermission(permission).result();
        if (result != QtAndroidPrivate::Authorized) {
          qCWarning(audioStreamRecorderLog)
            << "Permission is not granted:" << permission;
          /* NOTE: I'm not calling return here intentionally. 
           * These permissions might be not required by some devices
           */
        }
      }
    }
  });
#endif /* Q_OS_ANDROID */

  reset();

  m_startTime = QDateTime::currentDateTime();
  setRecording(true);
}

void AudioStreamRecorder::stop() {
  qCDebug(audioStreamRecorderLog) << "Stop";

  if (m_file->isOpen()) {
    saveRecording();
  }

  setRecording(false);
}

void AudioStreamRecorder::setRecording(bool recording) {
  if (recording != m_recording) {
    m_recording = recording;
    emit recordingChanged();
  }
}

AudioStreamRecorder::RecordingPolicy
AudioStreamRecorder::recordingPolicy() const {
  return m_recordingPolicy;
}

void AudioStreamRecorder::setRecordingPolicy(RecordingPolicy policy) {
  if (m_recordingPolicy != policy) {
    m_recordingPolicy = policy;
    emit recordingPolicyChanged();
  }
}

static QString dateTimePath() {
  return QDateTime::currentDateTime().toString("yyyy-MM-dd-hhmmss");
}

void AudioStreamRecorder::processBuffer(const QByteArray &buffer,
                                        const QUrl &streamUrl,
                                        const QString &id) {
  if (!m_recording) {
    return;
  }

  if (m_recordingPolicy == SaveRecordingWhenStreamTitleChanges &&
      m_streamTitle != id && !m_streamTitle.isEmpty() && m_file->isOpen()) {
    saveRecording();
  }

  if (m_streamUrl != streamUrl && m_file->isOpen()) {
    saveRecording();
  }

  if (!m_file->isOpen()) {
    QString dateTimeString = dateTimePath();

    m_file->setFileName(
      outputLocationToDir().filePath(u"YuRadio_"_s + dateTimeString));

    if (!m_file->open(QFile::ReadWrite)) {
      QString errorString = QString("Failed to open file for recording: %1 %2")
                              .arg(m_file->fileName())
                              .arg(m_file->errorString());
      setError(errorString);
      stop();

      qCWarning(audioStreamRecorderLog).noquote() << errorString;
      return;
    }
  }

  m_streamTitle = id;
  m_streamUrl = streamUrl;

  m_file->write(buffer);
}

void AudioStreamRecorder::setPreferredSuffix(const QString &preferredSuffix) {
  qCDebug(audioStreamRecorderLog) << "Set preferred suffix:" << preferredSuffix;
  m_preferredSuffix = preferredSuffix;
}

QString AudioStreamRecorder::recordingName() {
  QString streamTitle = m_streamTitle;
  if (streamTitle.isEmpty()) {
    streamTitle = u"UnknownTrack"_s;
  } else {
    static QRegularExpression re(u"[/\\?%*:|\"<>\\s]"_s);

    streamTitle.replace(re, "_");
  }

  switch (m_recordingNamePolicy) {
    case StationDateTime:
      return "YuRadio_" + dateTimePath();
    case StationTrackNameDateTime:
      return "YuRadio_" + streamTitle + '_' + dateTimePath();
    case StationTrackName:
      return "YuRadio_" + streamTitle;
  }
}

void AudioStreamRecorder::saveRecording() {
  qCDebug(audioStreamRecorderLog) << "Save Recording";

  if (m_file->isOpen()) {
    QString suffix = m_preferredSuffix;
    if (suffix.isEmpty()) {
      qCWarning(audioStreamRecorderLog())
        << "Suffix is empty using mp3 as fallback";
      suffix = u"mp3"_s;
    }

    QString finalName = QFile::encodeName(recordingName()) + '.' + suffix;

    m_file->close();

    QString finalPath = outputLocationToDir().filePath(finalName);

    qCDebug(audioStreamRecorderLog)
      << QString("Rename %1 to %2").arg(m_file->fileName()).arg(finalPath);

    if (!m_file->rename(finalPath)) {
      QString errorString =
        QString("Failed to rename recording file from %1 to %2. Reason: %3")
          .arg(m_file->fileName())
          .arg(finalPath)
          .arg(m_file->errorString());

      setError(errorString);

      qCWarning(audioStreamRecorderLog).noquote() << errorString;
    }
  } else {
    QString errorString = "Failed to save recording. File is closed";
    setError(errorString);

    qCWarning(audioStreamRecorderLog).noquote() << errorString;
  }
}

void AudioStreamRecorder::reset() {
  m_streamTitle = QString();

  if (m_file->isOpen()) {
    /* Remove temporary recording file */
    if (!m_file->remove()) {
      qCWarning(audioStreamRecorderLog)
        << "Cannot remove file:" << m_file->fileName() << m_file->errorString();
    }
  }

  m_streamUrl = QUrl();
  m_startTime = QDateTime();
  m_file->close();
}

AudioStreamRecorder::RecordingNamePolicy
AudioStreamRecorder::recordingNamePolicy() const {
  return m_recordingNamePolicy;
}

void AudioStreamRecorder::setRecordingNamePolicy(RecordingNamePolicy policy) {
  if (m_recordingNamePolicy != policy) {
    m_recordingNamePolicy = policy;
    emit recordingNamePolicyChanged();
  }
}

void AudioStreamRecorder::setError(const QString &errorString) {
  m_errorString = errorString;
  emit errorOccurred();
}

QString AudioStreamRecorder::errorString() const {
  return m_errorString;
}

QDir AudioStreamRecorder::outputLocationToDir() {
  QString filePath = m_outputLocation.isLocalFile()
                       ? m_outputLocation.toLocalFile()
                       : m_outputLocation.toString();

  return {filePath};
}
