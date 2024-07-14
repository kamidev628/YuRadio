#ifndef RADIOPLAYER_H
#define RADIOPLAYER_H

#include <QMediaPlayer>
#include <QtQml>

#include "icecastreader.h"

class QMediaDevices;
class QThread;

class RadioPlayer : public QMediaPlayer {
  Q_OBJECT
  Q_PROPERTY(
    QVariantMap icyMetaData READ icyMetaData NOTIFY icyMetaDataChanged FINAL)
  Q_PROPERTY(
    QUrl radioUrl READ radioUrl WRITE setRadioUrl NOTIFY radioUrlChanged FINAL)
  Q_PROPERTY(bool icecastHint READ icecastHint WRITE setIcecastHint NOTIFY
               icecastHintChanged FINAL)
  Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged FINAL)
  QML_ELEMENT

public:
  RadioPlayer(QObject *parent = nullptr);

  Q_INVOKABLE void playRadio();
  Q_INVOKABLE void toggleRadio();

  QVariantMap icyMetaData() const;

  QUrl radioUrl() const;
  void setRadioUrl(const QUrl &newRadioUrl);

  bool icecastHint() const;
  void setIcecastHint(bool newIcecastHint);

  qreal progress() const;

signals:
  void icyMetaDataChanged();
  void radioUrlChanged();

  void icecastHintChanged();

  void progressChanged();

protected:
  void setIcyMetaData(const QVariantMap &metaData);
  void setProgress(qreal newProgress);

private slots:
  void icecastBufferReady();

  void statusChanged(QMediaPlayer::MediaStatus status);
  void handleError(QMediaPlayer::Error error, const QString &errorString);

private:
  std::unique_ptr<IcecastReader> m_iceCastReader;
  QMediaDevices *m_mediaDevices;

  QUrl m_radioUrl;

  QVariantMap m_icyMetaData;

  QElapsedTimer m_startTimer;
  bool m_icecastHint;
  qreal m_progress;
};

#endif /* !RADIOPLAYER_H */
