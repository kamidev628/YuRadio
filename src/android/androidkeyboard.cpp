#include <QDebug>
#include <QJniEnvironment>
#include <QThread>

#include <QtCore/private/qandroidextras_p.h>

#include <QReadLocker>

#include "androidkeyboard.h"

static const char virtualKeyboardListenerClassName[] =
  "org/yuradio/VirtualKeyboardListener";

AndroidKeyboard::AndroidKeyboard(QObject *parent) : QObject{parent} {
  QJniObject virtualKeyboardListener(virtualKeyboardListenerClassName);
  QJniObject activity(QNativeInterface::QAndroidApplication::context());
  virtualKeyboardListener.callMethod<void>(
    "install", "(Landroid/app/Activity;)V", activity.object());
}

AndroidKeyboard *AndroidKeyboard::instance() {
  static AndroidKeyboard keyboard;
  return &keyboard;
}

int AndroidKeyboard::height() const {
  QReadLocker locker(&m_rwLock);
  return m_height;
}

void AndroidKeyboard::setHeight(int newHeight) {
  QWriteLocker locker(&m_rwLock);
  if (m_height != newHeight) {
    m_height = newHeight;
    emit heightChanged();
  }
}

void AndroidKeyboard::virtualKeyboardStateChanged(JNIEnv * /*env*/,
                                                  jobject /*thiz*/,
                                                  jint VirtualKeyboardHeight) {
  AndroidKeyboard *keyboard = AndroidKeyboard::instance();
  keyboard->setHeight(VirtualKeyboardHeight);
  qInfo() << "Keyboard height:" << VirtualKeyboardHeight;
}

void AndroidKeyboard::registerNativeMethods() {
  std::initializer_list<JNINativeMethod> methods = {
    {"VirtualKeyboardStateChanged", "(I)V",
     reinterpret_cast<void *>(virtualKeyboardStateChanged)}};

  QJniEnvironment env;
  env.registerNativeMethods(virtualKeyboardListenerClassName, methods);
}
