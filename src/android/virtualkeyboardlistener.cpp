#include <QJniEnvironment>
#include <QJniObject>

#include <QtCore/private/qandroidextras_p.h>

#include "virtualkeyboardlistener.h"

static const char virtualKeyboardListenerClassName[] =
  "org/yuradio/VirtualKeyboardListener";

VirtualKeyboardListener::VirtualKeyboardListener(QObject *parent)
    : QObject(parent) {
  QJniObject virtualKeyboardListener(virtualKeyboardListenerClassName);
  QJniObject context(QNativeInterface::QAndroidApplication::context());
  virtualKeyboardListener.callMethod<void>(
    "install", "(Landroid/content/Context;)V", context.object());
}

VirtualKeyboardListener *VirtualKeyboardListener::instance() {
  static VirtualKeyboardListener instance;
  return &instance;
}

static void virtualKeyboardHeightChanged(JNIEnv * /*env*/, jobject /*thiz*/,
                                         jint height) {
  VirtualKeyboardListener *keyboardListener =
    VirtualKeyboardListener::instance();
  emit keyboardListener->heightChanged(height);
}

Q_DECLARE_JNI_NATIVE_METHOD(virtualKeyboardHeightChanged);

void VirtualKeyboardListener::registerNativeMethods() {
  std::initializer_list<JNINativeMethod> methods = {
    Q_JNI_NATIVE_METHOD(virtualKeyboardHeightChanged),
  };

  QJniEnvironment env;
  env.registerNativeMethods(virtualKeyboardListenerClassName, methods);
}
