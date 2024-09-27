#include "application.h"

int main(int argc, char *argv[]) {
  if (qEnvironmentVariableIsEmpty("QT_LOGGING_RULES")) {
    qputenv("QT_LOGGING_RULES",
            "YuRadio.*.debug=true\nHotreloader.*.info=false\nYuRadio."
            "RadioInfoReaderProxyServer.info=false\nYuRadio.GlobalKeyListener."
            "info=false\nYuRest.NetworkManager.info=false");
  }

  Application app(argc, argv);

  return Application::exec();
}
