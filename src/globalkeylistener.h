#ifndef GLOBALKEYLISTENER_H
#define GLOBALKEYLISTENER_H

#include <QKeySequence>
#include <QObject>
#include <QtQmlIntegration>

#ifdef UIOHOOK_SUPPORTED
class GlobalKeyListener : public QObject {
  Q_OBJECT

public:
  explicit GlobalKeyListener();
  ~GlobalKeyListener() override;

  static GlobalKeyListener *instance();

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

#endif /* UIOHOOK_SUPPORTED */

class GlobalShortcut : public QObject {
  Q_OBJECT
  Q_PROPERTY(QVariant sequence READ sequence WRITE setSequence NOTIFY
               sequenceChanged FINAL)
  Q_PROPERTY(
    bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged FINAL)
  QML_ELEMENT

public:
  explicit GlobalShortcut(QObject *parent = nullptr);

  QVariant sequence() const;
  void setSequence(const QVariant &sequence);

  bool isEnabled() const;
  void setEnabled(bool enabled);

signals:
  void activated();
  void sequenceChanged();
  void enabledChanged();

private:
#ifdef UIOHOOK_SUPPORTED
  QKeySequence m_sequence;
  bool m_enabled;
#endif /* UIOHOOK_SUPPORTED */
};

#endif /* !GLOBALKEYLISTENER_H */
