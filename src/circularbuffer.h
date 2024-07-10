#ifndef CIRCULARBUFFER_H
#define CIRCULARBUFFER_H

#include <QByteArray>
#include <QIODevice>

class CircularBuffer : public QIODevice {
public:
  CircularBuffer(qint64 capacity, QObject *parent = nullptr);

  bool isSequential() const override;

  qint64 bytesAvailable() const override;
  qint64 size() const override;

  qint64 readData(char *data, qint64 maxlen) override;
  qint64 writeData(const char *data, qint64 maxlen) override;

  inline qint64 capacity() const { return m_buffer.size(); }

  void updateIndex(qint64 &index, qint64 bytes) const;

private:
  QByteArray m_buffer;

  qint64 m_front;
  qint64 m_rear;
  qint64 m_size;
};

#endif /* !CIRCULARBUFFER_H */
