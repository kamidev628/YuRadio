#include <QLoggingCategory>
Q_LOGGING_CATEGORY(applicationLog, "YuRadio.Application")

#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#ifdef Q_OS_ANDROID
#include "android/nativemediacontroller.h"
#include "android/notificationclient.h"
#include "android/virtualkeyboardlistener.h"
#endif /* Q_OS_ANDROID */

#ifdef QT_DEBUG
#include "hotreloaderclient.h"
#endif /* QT_DEBUG */

#include <QFileInfo>
#include <QNetworkInformation>
#include <QSslSocket>
#include <QThread>

#include "application.h"
#include "applicationconfig.h"

#include "memoryliterals.h"
#include "network/networkmanagerfactory.h"

using namespace Qt::StringLiterals;
using namespace MemoryLiterals;

QtMessageHandler g_originalHandler = nullptr;
static const char g_logFileName[] = "log.txt";

void logToFileMessageHandler(QtMsgType type, const QMessageLogContext &context,
                             const QString &msg) {
  QString message = qFormatLogMessage(type, context, msg);
  static FILE *f = fopen(g_logFileName, "a");
  fprintf(f, "%s\n", qPrintable(message));
  fflush(f);

  if (g_originalHandler) {
    (*g_originalHandler)(type, context, msg);
  }
}

Application::Application(int argc, char **argv) : QGuiApplication(argc, argv) {
  /* Format logging messages */
  qSetMessagePattern(
    u"%{if-category}%{category} %{endif}[%{time yyyy/MM/dd h:mm:ss.zzz} "
    "%{if-debug}Debug%{endif}%{if-info}Info%{endif}%{if-warning}Warning%{endif}"
    "%{if-critical}Critical%{endif}%{if-fatal}Fatal%{endif}]"
#ifdef QT_DEBUG
    " %{file}:%{line}"
#endif /* QT_DEBUG */
    " - %{message}"_s);
  g_originalHandler = qInstallMessageHandler(logToFileMessageHandler);

  QFileInfo logFileInfo(g_logFileName);
  if (static_cast<std::size_t>(logFileInfo.size()) > 2_MiB) {
    QFile::remove(g_logFileName);
  }

  QLoggingCategory::setFilterRules(
    u"YuRadio.*.debug=true\nHotreloader.*.info=false\nYuRadio.RadioInfoReaderProxyServer.info=false\nYuRadio.GlobalKeyListener.info=false\nYuRest.NetworkManager.info=false"_s);
  QThread::currentThread()->setObjectName("Main Thread"_L1);

  QCoreApplication::setOrganizationName(u"YuRadio"_s);

  if (QCoreApplication::applicationVersion().isEmpty()) {
    QCoreApplication::setApplicationVersion(YURADIO_VERSION);
  }

  qCInfo(applicationLog) << "Version:"
                         << QCoreApplication::applicationVersion();
  qCInfo(applicationLog) << "Device supports OpenSSL:"
                         << QSslSocket::supportsSsl();
#ifdef UIOHOOK_SUPPORTED
  qCInfo(applicationLog) << "Uiohook is enabled. GlobalKeyListener will work";
#else
  qCInfo(applicationLog)
    << "Uiohook is disabled. GlobalKeyListener will not work";
#endif

  if (!QNetworkInformation::loadDefaultBackend()) {
    qCWarning(applicationLog)
      << "Failed to load QNetworkInformation default backend (Reconnection to "
         "stations might not work)";
  }

  m_engine = std::make_unique<QQmlApplicationEngine>();

  QQuickStyle::setStyle(u"Material"_s);

  auto *networkManagerFactory = new NetworkManagerFactory(m_engine.get());
  m_engine->setNetworkAccessManagerFactory(networkManagerFactory);

  initializePlatform();

#ifdef QT_DEBUG
  new HotReloaderClient(m_engine.get(), u"192.168.1.37"_s,
                        u"/src/Main/Main.qml"_s, u"/src/Main/ErrorPage.qml"_s,
                        {u"Main"_s, u"YuRadioContents"_s}, this);
#else
  m_engine->loadFromModule(u"Main"_s, u"Main"_s);
#endif /* QT_DEBUG */
}

Application::~Application() = default;

void Application::initializePlatform() {
#ifdef Q_OS_ANDROID
  /* Rename android UI thread*/
  QNativeInterface::QAndroidApplication::runOnAndroidMainThread([]() {
    QThread::currentThread()->setObjectName("Android Main Thread"_L1);
  });

  auto *notificationClient = new NotificationClient(this);
  m_engine->rootContext()->setContextProperty("NotificationClient",
                                              notificationClient);

  NativeMediaController::registerNativeMethods();
  VirtualKeyboardListener::registerNativeMethods();
#endif /* Q_OS_ANDROID */
}
