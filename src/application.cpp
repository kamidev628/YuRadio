#include <QLoggingCategory>
Q_LOGGING_CATEGORY(applicationLog, "YuRadio.Application")

#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QSystemTrayIcon>

#ifdef Q_OS_ANDROID
#include "android/nativemediacontroller.h"
#include "android/notificationclient.h"
#include "android/virtualkeyboardlistener.h"
#endif /* Q_OS_ANDROID */

#ifdef HOTRELOADER_SUPPORTED
#include "hotreloaderclient.h"
#endif /* QT_DEBUG */

#include <QDirIterator>
#include <QNetworkInformation>
#include <QSslSocket>
#include <QStandardPaths>
#include <QThread>

#include "application.h"
#include "applicationconfig.h"
#include "logging.h"

#include "network/networkmanagerfactory.h"

using namespace Qt::StringLiterals;

Application::Application(int argc, char **argv) : QApplication(argc, argv) {
#if !defined(Q_OS_LINUX) || defined(Q_OS_ANDROID)
  QString packageVersion = QCoreApplication::applicationVersion();
  Q_ASSERT(packageVersion.startsWith(YURADIO_VERSION));
#endif

  QCoreApplication::setApplicationVersion(YURADIO_VERSION);
  QCoreApplication::setOrganizationName(u"YuRadio"_s);
  Logging::initialize();

  QLoggingCategory::setFilterRules(
    u"YuRadio.*.debug=true\nHotreloader.*.info=false\nYuRadio.RadioInfoReaderProxyServer.info=false\nYuRadio.GlobalKeyListener.info=false\nYuRest.NetworkManager.info=false"_s);
  QThread::currentThread()->setObjectName("Main Thread"_L1);

  qCInfo(applicationLog).noquote()
    << "Version:" << QCoreApplication::applicationVersion();
  qCInfo(applicationLog) << "Device supports OpenSSL:"
                         << QSslSocket::supportsSsl();
  qCInfo(applicationLog).noquote()
    << "CPU Architecture:" << QSysInfo::currentCpuArchitecture();
  qCInfo(applicationLog).noquote()
    << "Build CPU Architecture:" << QSysInfo::buildCpuArchitecture();
  qCInfo(applicationLog).noquote() << "Build ABI:" << QSysInfo::buildAbi();
  qCInfo(applicationLog).noquote()
    << "Platform:" << QSysInfo::prettyProductName();
#ifdef UIOHOOK_SUPPORTED
  qCInfo(applicationLog) << "Uiohook is enabled";
#else
  qCInfo(applicationLog) << "Uiohook is disabled";
#endif
  qCInfo(applicationLog) << "System tray available:"
                         << QSystemTrayIcon::isSystemTrayAvailable();

  if (!QNetworkInformation::loadDefaultBackend()) {
    qCWarning(applicationLog)
      << "Failed to load QNetworkInformation default backend (Reconnection to "
         "stations might not work)";
  }

  m_engine = std::make_unique<QQmlApplicationEngine>();

  QQuickStyle::setStyle(u"Material"_s);

  auto *networkManagerFactory = new NetworkManagerFactory(m_engine.get());
  m_engine->setNetworkAccessManagerFactory(networkManagerFactory);
  m_engine->rootContext()->setContextProperty(
    "AppConfig_trayIconAvailable", QSystemTrayIcon::isSystemTrayAvailable());

  initializePlatform();

#ifdef HOTRELOADER_SUPPORTED
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
