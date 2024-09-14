#ifndef DOWNLOADSPEEDMEASURER
#define DOWNLOADSPEEDMEASURER

#include <QElapsedTimer>
#include <QObject>
#include <QQueue>
#include <QTimer>

class DownloadSpeedMeasurer : public QObject {
  Q_OBJECT
public:
  explicit DownloadSpeedMeasurer(QObject *parent = nullptr);

  void start();
  void measure(qint64 numBytes);
  void invalidate();

  void setWindowInterval(std::chrono::milliseconds interval);

  bool isValid();

  float estimatedSpeed();

signals:
  void estimatedSpeedChanged(float estimatedSpeed);

private:
  struct DownloadTimestamp {
    std::chrono::milliseconds elapsed;
    qint64 bytes;
  };

  QQueue<DownloadTimestamp> m_timestamps;

  QElapsedTimer m_timer;
  QTimer m_updateTimer;

  std::chrono::milliseconds m_totalTime;
  std::chrono::milliseconds m_windowInterval;

  qint64 m_totalBytes;
};

#endif /* !DOWNLOADSPEEDMEASURER */
