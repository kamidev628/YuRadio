#include <QLoggingCategory>
#include <QThread>
Q_LOGGING_CATEGORY(circularBufferLog, "YuRadio.CircularBuffer")

#include "circularbuffer.h"

CircularBuffer::CircularBuffer(qint64 capacity, QObject *parent)
    : QIODevice(parent), m_front(0), m_rear(0), m_size(0) {
  m_buffer.resize(capacity);
}

bool CircularBuffer::isSequential() const {
  return true;
}

qint64 CircularBuffer::bytesAvailable() const {
  return m_size + QIODevice::bytesAvailable();
}

qint64 CircularBuffer::size() const {
  return m_size;
}

qint64 CircularBuffer::readData(char *data, qint64 maxlen) {
  qCDebug(circularBufferLog) << "Read:" << maxlen << "Current Size:" << m_size
                             << "Thread:" << QThread::currentThread();

  maxlen = qMin(maxlen, m_size);
  qint64 bytesRead = qMin(maxlen, capacity() - m_front);

  std::memcpy(data, m_buffer.data() + m_front, static_cast<size_t>(bytesRead));
  std::memcpy(data + bytesRead, m_buffer.data(),
              static_cast<size_t>(maxlen - bytesRead));

  updateIndex(m_front, maxlen);

  m_size -= maxlen;
  return maxlen;
}

qint64 CircularBuffer::writeData(const char *data, qint64 maxlen) {
  qCDebug(circularBufferLog) << "Write:" << maxlen << "Current Size:" << m_size
                             << "Thread:" << QThread::currentThread();

  maxlen = qMin(maxlen, capacity() - size());
  qint64 bytesWrite = qMin(maxlen, capacity() - m_rear);

  std::memcpy(m_buffer.data() + m_rear, data, static_cast<size_t>(bytesWrite));
  std::memcpy(m_buffer.data(), data + bytesWrite,
              static_cast<size_t>(maxlen - bytesWrite));

  updateIndex(m_rear, maxlen);

  m_size += maxlen;
  return maxlen;
}

void CircularBuffer::updateIndex(qint64 &index, qint64 bytes) const {
  index = (index + bytes) % capacity();
}
