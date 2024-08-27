#ifndef GLOBALKEYLISTENER_H
#define GLOBALKEYLISTENER_H

#include <QObject>

class GlobalKeyListener : public QObject {
  Q_OBJECT

public:
  explicit GlobalKeyListener();
  ~GlobalKeyListener() override;

signals:
  void keyPressed(Qt::Key key);
  void keyReleased(Qt::Key key);
  void keyTyped(Qt::Key key);

private:
  void cleanup();
  void run();

private:
  std::unique_ptr<QThread> m_thread;
};

#endif /* !GLOBALKEYLISTENER_H */
