#ifndef ANDROIDKEYBOARD_H
#define ANDROIDKEYBOARD_H

#include <QObject>
#include <QtQmlIntegration>

class QQmlEngine;
class QJSEngine;
class VirtualKeyboardListener;

class AndroidKeyboard : public QObject {
  Q_OBJECT
  Q_PROPERTY(int height READ height NOTIFY heightChanged FINAL)
  QML_SINGLETON
  QML_ELEMENT

public:
  explicit AndroidKeyboard(QObject *parent = nullptr);
  static AndroidKeyboard *instance();
  static AndroidKeyboard *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

  int height() const;

signals:
  void heightChanged();

private:
  void setHeight(int height);

private:
  VirtualKeyboardListener *m_keyboardListener;
  int m_height;
};

#endif  // ANDROIDKEYBOARD_H
