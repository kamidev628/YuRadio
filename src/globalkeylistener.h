#ifndef GLOBALKEYLISTENER_H
#define GLOBALKEYLISTENER_H

#include <QObject>
#include <QPointer>

class GlobalShortcut;

class GlobalKeyListener : public QObject {
  Q_OBJECT

public:
  explicit GlobalKeyListener();
  ~GlobalKeyListener() override;

signals:
  void keyPressed(Qt::Key key, Qt::KeyboardModifiers modifiers);
  void keyReleased(Qt::Key key, Qt::KeyboardModifiers modifiers);
  void keyTyped(Qt::Key key, Qt::KeyboardModifiers modifiers);

private:
  void cleanup();
  void start();

private:
  std::unique_ptr<QThread> m_thread;
};

class GlobalShortcut : public QObject {
  Q_OBJECT

public:
  explicit GlobalShortcut(Qt::Key key,
                          Qt::KeyboardModifiers modifiers = Qt::NoModifier,
                          QObject *parent = nullptr);

  void registerShortcut(GlobalKeyListener *listener);

  Qt::Key key() const;
  Qt::KeyboardModifiers modifiers() const;

signals:
  void activated();

private:
  Qt::Key m_key;
  Qt::KeyboardModifiers m_modifiers;
};

#endif /* !GLOBALKEYLISTENER_H */
