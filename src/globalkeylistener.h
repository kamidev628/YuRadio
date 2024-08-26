#ifndef GLOBALKEYLISTENER_H
#define GLOBALKEYLISTENER_H

#include <QObject>

class GlobalKeyListener : public QObject {
  Q_OBJECT

public:
  explicit GlobalKeyListener(QObject *parent = nullptr);
  ~GlobalKeyListener() override;

  static GlobalKeyListener *instance();

  void cleanup();

signals:
  void keyPressed(Qt::Key key);
  void keyReleased(Qt::Key key);
  void keyTyped(Qt::Key key);

private:
  void cleanupImpl();
  void run();

private:
  Q_DISABLE_COPY(GlobalKeyListener)

  std::unique_ptr<QThread> m_thread;
};

#endif /* !GLOBALKEYLISTENER_H */
