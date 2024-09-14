#include <QLoggingCategory>
Q_LOGGING_CATEGORY(downloadSpeedMeasurerLog, "YuRadio.DownloadSpeedMeasurer")

#include <QTimer>

#include "downloadspeedmeasurer.h"

using namespace std::chrono_literals;

DownloadSpeedMeasurer::DownloadSpeedMeasurer(QObject *parent)
    : QObject(parent), m_totalTime(0ms), m_windowInterval(2s), m_totalBytes(0) {
  m_updateTimer.setInterval(300ms);
  m_updateTimer.setSingleShot(false);

  connect(&m_updateTimer, &QTimer::timeout, this, [this]() { measure(0); });
}

void DownloadSpeedMeasurer::measure(qint64 numBytes) {
  if (!m_timer.isValid()) {
    m_timer.start();
    m_updateTimer.start();
    return;
  }

  std::chrono::milliseconds elapsed(m_timer.elapsed());

  if (elapsed > 0ms) {
    DownloadTimestamp downloadTimestamp{elapsed, numBytes};

    m_totalTime += elapsed;
    m_totalBytes += numBytes;

    m_timestamps.enqueue(downloadTimestamp);

    while (m_totalTime > m_windowInterval && !m_timestamps.isEmpty()) {
      DownloadTimestamp timestamp = m_timestamps.dequeue();
      m_totalTime -= timestamp.elapsed;
      m_totalBytes -= timestamp.bytes;
    }

    if (m_totalTime > 0ms) {
      float downloadSpeed = estimatedSpeed();
      qCDebug(downloadSpeedMeasurerLog)
        << "Download Speed(kbps):" << downloadSpeed * 8;
      estimatedSpeedChanged(downloadSpeed);
    }
  }

  m_timer.start();
}

void DownloadSpeedMeasurer::start() {
  m_timer.start();
  m_updateTimer.start();
}

void DownloadSpeedMeasurer::invalidate() {
  m_timer.invalidate();
  m_updateTimer.stop();
  m_timestamps.clear();
  m_totalTime = 0ms;
  m_totalBytes = 0;
}

bool DownloadSpeedMeasurer::isValid() {
  return m_timer.isValid() && m_totalTime > 0ms && m_windowInterval > 0ms &&
         m_totalBytes > 0;
}

void DownloadSpeedMeasurer::setWindowInterval(
  std::chrono::milliseconds interval) {
  m_windowInterval = interval;
}

float DownloadSpeedMeasurer::estimatedSpeed() {
  return static_cast<float>(m_totalBytes) /
         static_cast<float>(m_totalTime.count());
}
