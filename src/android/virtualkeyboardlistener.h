#ifndef VIRTUALKEYBOARDLISTENER_H
#define VIRTUALKEYBOARDLISTENER_H

#include <QObject>

/**
 * @class VirtualKeyboardListener
 * @brief Wrapper class for VirtualKeyboardListener.java
 *
 * @ref https://falsinsoft.blogspot.com/2017/04/qml-resize-controls-when-android.html
 *
 */
class VirtualKeyboardListener : public QObject {
  Q_OBJECT

public:
  explicit VirtualKeyboardListener(QObject *parent = nullptr);

  static VirtualKeyboardListener *instance();
  static void registerNativeMethods();

signals:
  void heightChanged(int height);
};

#endif /* !VIRTUALKEYBOARDLISTENER_H */
