#ifndef BASICRADIOCONTROLLER_H
#define BASICRADIOCONTROLLER_H

#include <QMediaPlayer>

#include "platformradiocontroller.h"

class QMediaDevices;
class IcecastReader;
class IcecastReaderProxyServer;

class BasicRadioController : public PlatformRadioController {
  Q_OBJECT

public:
  BasicRadioController(QObject *parent = nullptr);

  void play() override;
  void stop() override;
  void pause() override;

  void setSource(const QUrl &source) override;

private slots:
  void statusChanged(QMediaPlayer::MediaStatus status);

private:
  IcecastReaderProxyServer *m_icecastProxy;
  QMediaPlayer *m_mediaPlayer;
  QMediaDevices *m_mediaDevices;
};

#endif /* !BASICRADIOCONTROLLER_H */
