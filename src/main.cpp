#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#ifdef Q_OS_ANDROID
  #include "android/androidkeyboard.h"
  #include "android/nativemediacontroller.h"
#endif /* Q_OS_ANDROID */

#ifdef QT_DEBUG
  #include "hotreloaderclient.h"
#endif /* QT_DEBUG */

#include <QDir>
#include <QThread>

#include <QLoggingCategory>
#include <QSslSocket>

using namespace Qt::StringLiterals;

int main(int argc, char *argv[]) {
  /* Format debug messages */
  qSetMessagePattern(QStringLiteral(
    "[%{time yyyy/MM/dd h:mm:ss.zzz} "
    "%{if-debug}D%{endif}%{if-info}I%{endif}%{if-warning}W%{endif}%{if-"
    "critical}C%{endif}%{if-fatal}F%{endif}] %{file}:%{line} - %{message}"));

  QLoggingCategory::setFilterRules(QStringLiteral(
    "YuRadio.*.debug=true\nYuRadio.CircularBuffer.debug="
    "false\nHotreloader.*.info=false\nYuRadio.IcecastReader.info=false"));
  QThread::currentThread()->setObjectName("Main Thread"_L1);

  QGuiApplication app(argc, argv);

  QCoreApplication::setOrganizationName(QStringLiteral("YuRadio"));
  QCoreApplication::setApplicationName(QStringLiteral("YuRadio"));
  QCoreApplication::setApplicationVersion(QStringLiteral("1.0"));

  QQmlApplicationEngine engine;
  QQuickStyle::setStyle(QStringLiteral("Material"));

  qDebug() << "Version:" << QCoreApplication::applicationVersion();

  qDebug() << "Device supports OpenSSL:" << QSslSocket::supportsSsl();
#ifdef Q_OS_ANDROID
  /* Rename android UI thread*/
  QNativeInterface::QAndroidApplication::runOnAndroidMainThread([]() {
    QThread::currentThread()->setObjectName("Android Main Thread"_L1);
  });
  NativeMediaController::registerNativeMethods();
  AndroidKeyboard::registerNativeMethods();

  engine.rootContext()->setContextProperty("androidKeyboard",
                                           AndroidKeyboard::instance());
#endif /* Q_OS_ANDROID */

#ifdef QT_DEBUG
  HotReloaderClient client(&engine, "192.168.1.37", "/src/Main/Main.qml",
                           "/src/Main/ErrorPage.qml",
                           {"Main", "YuRadioContents"});
#else
  engine.loadFromModule("Main", "Main");
#endif /* QT_DEBUG */

  return app.exec();
}
