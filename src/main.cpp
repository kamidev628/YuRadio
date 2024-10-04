#include "application.h"

int main(int argc, char *argv[]) {
  if (qEnvironmentVariableIsEmpty("QT_LOGGING_RULES")) {
    qputenv("QT_LOGGING_RULES",
            "YuRadio.*.debug=true\nHotreloader.*.info=false\nYuRadio."
            "RadioInfoReaderProxyServer.*=true\nYuRadio.GlobalKeyListener."
            "info=false\nYuRest.NetworkManager.info=false");
  }
  if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_MATERIAL_VARIANT")) {
#if defined(Q_OS_WIN) || (defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)) ||    \
  defined(Q_OS_MACOS)
    qputenv("QT_QUICK_CONTROLS_MATERIAL_VARIANT", "Dense");
#endif /* if defined(Q_OS_WIN) || (defined(Q_OS_LINUX) && !defined(Q_OS_ANDROID)) ||    \
      defined(Q_OS_MACOS) */
  }

  Application app(argc, argv);

  return Application::exec();
}
