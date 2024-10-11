#include <QLoggingCategory>
Q_LOGGING_CATEGORY(audioStreamRecorderLog, "YuRadio.AudioStreamRecorder")

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
  return QDateTime::currentDateTime().toString("ddMMyyyy-hhmmss");
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
    QDir outputDir(m_outputLocation.toLocalFile());

    m_file->setFileName(outputDir.filePath(u"YuRadio_"_s + dateTimeString));
    if (!m_file->open(QFile::ReadWrite)) {
      stop();

      qCWarning(audioStreamRecorderLog)
        << "Failed to open file for recording:" << m_file->fileName()
        << m_file->errorString();
      return;
    }
  }

  m_streamTitle = id;
  m_streamUrl = streamUrl;

  m_file->write(buffer);
}

void AudioStreamRecorder::setPreferredSuffix(const QString &preferredSuffix) {
  m_preferredSuffix = preferredSuffix;
}

QString AudioStreamRecorder::recordingName() {
  switch (m_recordingNamePolicy) {
    case StationDateTime:
      return "YuRadio_" + dateTimePath();
    case StationTrackNameDateTime:
      return "YuRadio_" + m_streamTitle + '_' + dateTimePath();
    case StationTrackName:
      return "YuRadio_" + m_streamTitle;
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
    qCDebug(audioStreamRecorderLog) << "Rename to:" << finalName;

    m_file->close();

    QDir outputDir(m_outputLocation.toLocalFile());

    if (!m_file->rename(outputDir.filePath(finalName))) {
      qCWarning(audioStreamRecorderLog)
        << "Cannot rename recording:" << m_file->errorString();
    }
  } else {
    qCWarning(audioStreamRecorderLog)
      << "Cannot save recording:" << m_file->errorString();
  }
}

void AudioStreamRecorder::reset() {
  m_streamTitle = QString();
  m_preferredSuffix = QString();

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
