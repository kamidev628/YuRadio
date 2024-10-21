#ifndef APPLICATION_H
#define APPLICATION_H

class QQmlApplicationEngine;
class GlobalKeyListener;

#include <QtQmlIntegration>
#include <QtSystemDetection>

#ifdef Q_OS_ANDROID
#include <QGuiApplication>

using BaseApplicationClass = QGuiApplication;
#else
#include <QApplication>

using BaseApplicationClass = QApplication;
#endif /* Q_OS_ANDROID */

class Application : public BaseApplicationClass {
  Q_OBJECT

public:
  explicit Application(int argc, char **argv);
  ~Application() override;

private:
  void initializePlatform();

private:
  std::unique_ptr<QQmlApplicationEngine> m_engine;
};

class QmlApplication : public QObject {
  Q_OBJECT
  QML_ELEMENT
  QML_SINGLETON

public:
  explicit QmlApplication(QObject *parent = nullptr);

  /**
   * @brief Called by qml when application done loading
   */
  Q_INVOKABLE void applicationLoaded();
};

#endif /* !APPLICATION_H */
