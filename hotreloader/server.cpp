#include <QCoreApplication>

#include <QDebug>

#include "hotreloaderserver.h"

int main(int argc, char *argv[]) {
  QCoreApplication app(argc, argv);

  HotReloaderServer server(3030, 80);
  server.setIgnoreDirs({"build"});
  server.setQmlSourceDir(QDir::currentPath());
  server.setWatchDirectory(QDir::currentPath() + "/../..");

  return app.exec();
}
