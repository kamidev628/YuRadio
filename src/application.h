#ifndef APPLICATION_H
#define APPLICATION_H

#include <QGuiApplication>

class QQmlApplicationEngine;

class Application : public QGuiApplication {
  Q_OBJECT

public:
  explicit Application(int argc, char **argv);
  ~Application() override;

private:
  std::unique_ptr<QQmlApplicationEngine> m_engine;
};

#endif /* !APPLICATION_H */
