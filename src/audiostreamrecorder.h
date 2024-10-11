#ifndef AUDIOSTREAMRECORDER_H
#define AUDIOSTREAMRECORDER_H

#include <QObject>
#include <QtQml>

class AudioStreamRecorder : public QObject {
  Q_OBJECT
  Q_PROPERTY(QUrl outputLocation READ outputLocation WRITE setOutputLocation
               NOTIFY outputLocationChanged)
  Q_PROPERTY(bool recording READ recording NOTIFY recordingChanged)
  Q_PROPERTY(RecordingPolicy recordingPolicy READ recordingPolicy WRITE
               setRecordingPolicy NOTIFY recordingPolicyChanged)
  Q_PROPERTY(RecordingNamePolicy recordingNamePolicy READ recordingNamePolicy
               WRITE setRecordingNamePolicy NOTIFY recordingNamePolicyChanged)
  Q_PROPERTY(QString errorString READ errorString NOTIFY errorOccurred)
  QML_ELEMENT

public:
  explicit AudioStreamRecorder(QObject *parent = nullptr);
  ~AudioStreamRecorder() override;

  enum RecordingNamePolicy {
    StationDateTime = 0,
    StationTrackNameDateTime,
    StationTrackName,
  };
  Q_ENUM(RecordingNamePolicy)

  enum RecordingPolicy {
    NoRecordingPolicy = 0,
    SaveRecordingWhenStreamTitleChanges,
  };
  Q_ENUM(RecordingPolicy)

  QUrl outputLocation() const;
  void setOutputLocation(const QUrl &outputLocation);
  bool recording() const;

  RecordingPolicy recordingPolicy() const;
  void setRecordingPolicy(RecordingPolicy policy);

  RecordingNamePolicy recordingNamePolicy() const;
  void setRecordingNamePolicy(RecordingNamePolicy policy);

  QString errorString() const;

  Q_INVOKABLE void record();
  Q_INVOKABLE void stop();

  void reset();

public slots:
  void processBuffer(const QByteArray &buffer, const QUrl &streamUrl,
                     const QString &id);
  void setPreferredSuffix(const QString &preferredSuffix);

signals:
  void outputLocationChanged();
  void recordingChanged();
  void recordingPolicyChanged();
  void recordingNamePolicyChanged();
  void errorOccurred();

protected:
  void setError(const QString &errorString);
  void setRecording(bool recording);
  void saveRecording();
  QString recordingName();
  QDir outputLocationToDir();

private:
  QUrl m_outputLocation;
  QUrl m_streamUrl;
  QString m_streamTitle;
  QString m_preferredSuffix;
  QString m_errorString;
  RecordingPolicy m_recordingPolicy;
  RecordingNamePolicy m_recordingNamePolicy;

  QDateTime m_startTime;

  QFile *m_file;

  bool m_recording;
};

#endif /* !AUDIOSTREAMRECORDER_H */
