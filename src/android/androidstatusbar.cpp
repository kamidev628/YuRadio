#include <QtCore/private/qandroidextras_p.h>

#include "androidstatusbar.h"

AndroidStatusBar::AndroidStatusBar(QObject *parent) : QObject(parent) {
  QJniObject activity(QNativeInterface::QAndroidApplication::context());

  m_window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");
}

QColor AndroidStatusBar::color() const {
  return m_color;
}

void AndroidStatusBar::setColor(const QColor &color) {
  if (m_color != color) {
    m_color = color;

    update();

    emit colorChanged();
  }
}

void AndroidStatusBar::update() {
  QNativeInterface::QAndroidApplication::runOnAndroidMainThread([=]() {
    m_window.callMethod<void>("addFlags", "(I)V",
                              0x80000000);  // FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS
    m_window.callMethod<void>("clearFlags", "(I)V",
                              0x04000000);  // FLAG_TRANSLUCENT_STATUS
    m_window.callMethod<void>("setStatusBarColor", "(I)V",
                              m_color.rgba());  // Desired statusbar color
  });
}
