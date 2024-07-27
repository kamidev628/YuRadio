#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>

#ifdef Q_OS_ANDROID
  #include "android/androidkeyboard.h"
  #include "android/nativemediacontroller.h"
#endif /* Q_OS_ANDROID */

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
  NativeMediaController::registerNativeMethods();
  AndroidKeyboard::registerNativeMethods();
  /* Rename android UI thread*/
  QNativeInterface::QAndroidApplication::runOnAndroidMainThread([]() {
    QThread::currentThread()->setObjectName("Android Main Thread"_L1);
  });

  engine.rootContext()->setContextProperty("androidKeyboard",
                                           AndroidKeyboard::instance());
#endif /* Q_OS_ANDROID */

  engine.loadFromModule("Main", "Main");

  return app.exec();
}
