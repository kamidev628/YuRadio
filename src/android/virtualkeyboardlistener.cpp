#include <QJniEnvironment>
#include <QJniObject>

#include <QtCore/private/qandroidextras_p.h>

#include "virtualkeyboardlistener.h"

static const char virtualKeyboardListenerClassName[] =
  "org/yuradio/VirtualKeyboardListener";

VirtualKeyboardListener::VirtualKeyboardListener(QObject *parent)
    : QObject(parent) {
  QJniObject virtualKeyboardListener(virtualKeyboardListenerClassName);
  QJniObject activity(QNativeInterface::QAndroidApplication::context());
  virtualKeyboardListener.callMethod<void>(
    "install", "(Landroid/app/Activity;)V", activity.object());
}

VirtualKeyboardListener *VirtualKeyboardListener::instance() {
  static VirtualKeyboardListener instance;
  return &instance;
}

static void virtualKeyboardStateChanged(JNIEnv * /*env*/, jobject /*thiz*/,
                                        jint height) {
  VirtualKeyboardListener *keyboardListener =
    VirtualKeyboardListener::instance();
  emit keyboardListener->heightChanged(height);
}

void VirtualKeyboardListener::registerNativeMethods() {
  std::initializer_list<JNINativeMethod> methods = {
    {"VirtualKeyboardStateChanged", "(I)V",
     reinterpret_cast<void *>(virtualKeyboardStateChanged)}};

  QJniEnvironment env;
  env.registerNativeMethods(virtualKeyboardListenerClassName, methods);
}
