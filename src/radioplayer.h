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
  QML_ELEMENT

public:
  RadioPlayer(QObject *parent = nullptr);

  Q_INVOKABLE void playRadio();

  QVariantMap icyMetaData() const;

  QUrl radioUrl() const;
  void setRadioUrl(const QUrl &newRadioUrl);

signals:
  void icyMetaDataChanged();
  void radioUrlChanged();

private:
  void setIcyMetaData(const QVariantMap &metaData);

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
};

#endif /* !RADIOPLAYER_H */
