#include <QQmlEngine>

#include "android/virtualkeyboardlistener.h"
#include "androidkeyboard.h"

AndroidKeyboard::AndroidKeyboard(QObject *parent)
    : QObject{parent}, m_keyboardListener(VirtualKeyboardListener::instance()) {
  connect(m_keyboardListener, &VirtualKeyboardListener::heightChanged, this,
          &AndroidKeyboard::setHeight);
}

AndroidKeyboard *AndroidKeyboard::instance() {
  static AndroidKeyboard keyboard;
  return &keyboard;
}

int AndroidKeyboard::height() const {
  return m_height;
}

void AndroidKeyboard::setHeight(int height) {
  if (m_height != height) {
    m_height = height;
    emit heightChanged();
  }
}

AndroidKeyboard *AndroidKeyboard::create(QQmlEngine * /*qmlEngine*/,
                                         QJSEngine * /*jsEngine*/) {
  AndroidKeyboard *keyboard = AndroidKeyboard::instance();
  QQmlEngine::setObjectOwnership(keyboard, QQmlEngine::CppOwnership);
  return keyboard;
}
