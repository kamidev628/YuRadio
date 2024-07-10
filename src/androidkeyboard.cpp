#include <QDebug>

#include "androidkeyboard.h"

void AndroidKeyboard::virtualKeyboardStateChanged(JNIEnv * /*env*/,
                                                  jobject /*thiz*/,
                                                  jint VirtualKeyboardHeight) {
  AndroidKeyboard *keyboard = AndroidKeyboard::instance();
  keyboard->setHeight(VirtualKeyboardHeight);
  qInfo() << "Keyboard height:" << VirtualKeyboardHeight;
}

AndroidKeyboard::AndroidKeyboard(QObject *parent) : QObject{parent} {
  JNINativeMethod methods[] = {
    {"VirtualKeyboardStateChanged", "(I)V",
     reinterpret_cast<void *>(virtualKeyboardStateChanged)}};

  QJniObject javaClass("org/yuradio/VirtualKeyboardListener");
  QJniEnvironment env;

  jclass objectClass = env->GetObjectClass(javaClass.object<jobject>());

  env->RegisterNatives(objectClass, methods,
                       sizeof(methods) / sizeof(methods[0]));
  env->DeleteLocalRef(objectClass);

  QJniObject::callStaticMethod<void>("org/yuradio/VirtualKeyboardListener",
                                     "InstallKeyboardListener");
}

int AndroidKeyboard::height() const {
  return m_height;
}

void AndroidKeyboard::setHeight(int newHeight) {
  if (m_height != newHeight) {
    m_height = newHeight;
    emit heightChanged();
  }
}
