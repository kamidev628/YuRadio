#ifndef ANDROID_STATUSBAR_H
#define ANDROID_STATUSBAR_H

#include <QColor>
#include <QJniObject>
#include <QObject>
#include <QtQmlIntegration>

class AndroidStatusBar : public QObject {
  Q_OBJECT
  Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
  QML_SINGLETON
  QML_ELEMENT

public:
  explicit AndroidStatusBar(QObject *parent = nullptr);

  QColor color() const;
  void setColor(const QColor &color);

  Q_INVOKABLE void update();

signals:
  void colorChanged();

private:
  QJniObject m_window;

  QColor m_color;
};

#endif /* !ANDROID_STATUSBAR_H */
