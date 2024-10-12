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
  Q_PROPERTY(RecordingNameFormat recordingNameFormat READ recordingNameFormat
               WRITE setRecordingNameFormat NOTIFY recordingNameFormatChanged)
  Q_PROPERTY(QString errorString READ errorString NOTIFY errorOccurred)
  Q_PROPERTY(QString stationName READ stationName WRITE setStationName NOTIFY
               stationNameChanged)
  QML_ELEMENT

public:
  explicit AudioStreamRecorder(QObject *parent = nullptr);
  ~AudioStreamRecorder() override;

  enum RecordingNameFormat {
    StationDateTime = 0,
    StationTrackNameDateTime,
    TrackNameDateTime,
  };
  Q_ENUM(RecordingNameFormat)

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

  RecordingNameFormat recordingNameFormat() const;
  void setRecordingNameFormat(RecordingNameFormat format);

  QString errorString() const;

  QString stationName() const;
  void setStationName(const QString &stationName);

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
  void recordingNameFormatChanged();
  void stationNameChanged();
  void errorOccurred();

protected:
  void setError(const QString &errorString);
  void setRecording(bool recording);
  void saveRecording();
  QString recordingName() const;
  QString dateTimePath() const;
  QDir outputLocationToDir() const;

private:
  QUrl m_outputLocation;
  QUrl m_streamUrl;
  QString m_streamTitle;
  QString m_preferredSuffix;
  QString m_errorString;
  QString m_stationName;
  RecordingPolicy m_recordingPolicy;
  RecordingNameFormat m_recordingNameFormat;

  QDateTime m_startTime;

  QFile *m_file;

  bool m_recording;
};

#endif /* !AUDIOSTREAMRECORDER_H */
