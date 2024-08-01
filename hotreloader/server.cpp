#include <QCoreApplication>

#include <QDebug>

#include "hotreloader.h"
#include "hotreloaderserver.h"

int main(int argc, char *argv[]) {
  QCoreApplication app(argc, argv);

  HotReloaderServer server(HOTRELOADER_WEBSOCKET_PORT, HOTRELOADER_HTTP_PORT);
  server.setIgnoreDirs({"build"});
  server.setQmlSourceDir(QDir::currentPath());
  server.setWatchDirectory(QDir::currentPath() + "/../..");

  return app.exec();
}
