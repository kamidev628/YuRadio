#include <QGuiApplication>
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

#include <QDir>
#include <QThread>

#include <QLoggingCategory>
#include <QSslSocket>

#include "network/networkmanagerfactory.h"
#include <QKeySequence>
#include <QShortcut>

#ifdef UIOHOOK_SUPPORTED
  #include "globalkeylistener.h"
  #include "radioplayer.h"
#endif /* !UIOHOOK_SUPPORTED */

using namespace Qt::StringLiterals;

int main(int argc, char *argv[]) {
  /* Format debug messages */
  qSetMessagePattern(
    u"[%{time yyyy/MM/dd h:mm:ss.zzz} "
    "%{if-debug}D%{endif}%{if-info}I%{endif}%{if-warning}W%{endif}%{if-"
    "critical}C%{endif}%{if-fatal}F%{endif}] %{file}:%{line} - %{message}"_s);

  QLoggingCategory::setFilterRules(
    u"YuRadio.*.debug=true\nYuRadio.CircularBuffer.debug="
    "false\nHotreloader.*.info=false\nYuRadio.IcecastReader.info=false"_s);
  QThread::currentThread()->setObjectName("Main Thread"_L1);

  QGuiApplication app(argc, argv);

  QCoreApplication::setOrganizationName(u"YuRadio"_s);
  QCoreApplication::setApplicationName(u"YuRadio"_s);
  QCoreApplication::setApplicationVersion(u"1.0"_s);

  qDebug() << "Version:" << QCoreApplication::applicationVersion();
  qDebug() << "Device supports OpenSSL:" << QSslSocket::supportsSsl();

  QQmlApplicationEngine engine;
  QQuickStyle::setStyle(u"Material"_s);

  NetworkManagerFactory networkManagerFactory;
  engine.setNetworkAccessManagerFactory(&networkManagerFactory);

#ifdef UIOHOOK_SUPPORTED
  engine.rootContext()->setContextProperty("UIOHOOK_SUPPORTED", true);
  auto *player = engine.singletonInstance<RadioPlayer *>("YuRadioContents",
                                                         "MainRadioPlayer");
  GlobalKeyListener *listener = GlobalKeyListener::instance();
  QObject::connect(listener, &GlobalKeyListener::keyPressed, player,
                   [&](Qt::Key key) {
    if (key == Qt::Key_MediaPlay || key == Qt::Key_MediaStop ||
        key == Qt::Key_MediaPause) {
      player->toggle();
    }
  });
#else
  engine.rootContext()->setContextProperty("UIOHOOK_SUPPORTED", false);
#endif /* UIOHOOK_SUPPORTED */

#ifdef Q_OS_ANDROID
  /* Rename android UI thread*/
  QNativeInterface::QAndroidApplication::runOnAndroidMainThread([]() {
    QThread::currentThread()->setObjectName("Android Main Thread"_L1);
  });

  NotificationClient notificationClient;
  engine.rootContext()->setContextProperty("NotificationClient",
                                           &notificationClient);

  NativeMediaController::registerNativeMethods();
  VirtualKeyboardListener::registerNativeMethods();
#endif /* Q_OS_ANDROID */

#ifdef QT_DEBUG
  HotReloaderClient client(&engine, u"192.168.1.37"_s, u"/src/Main/Main.qml"_s,
                           u"/src/Main/ErrorPage.qml"_s,
                           {u"Main"_s, u"YuRadioContents"_s});
#else
  engine.loadFromModule(u"Main"_s, u"Main"_s);
#endif /* QT_DEBUG */

  return app.exec();
}
