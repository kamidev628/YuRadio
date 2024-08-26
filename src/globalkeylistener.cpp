#include <QDebug>
#include <QThread>

#include <uiohook.h>

#include "globalkeylistener.h"
#include <QKeyEvent>

static inline Qt::Key UioHookKeyToQt(uint16_t keycode) {
  switch (keycode) {
    /* TODO: Add all keys */
    case VC_MEDIA_PLAY:
      return Qt::Key_MediaPlay;
    case VC_MEDIA_STOP:
      return Qt::Key_MediaStop;
    case VC_MEDIA_NEXT:
      return Qt::Key_MediaNext;
    case VC_MEDIA_PREVIOUS:
      return Qt::Key_MediaPrevious;
    default:
      return Qt::Key_unknown;
  }
}

static void uiohookEventCallback(uiohook_event *const event) {
  GlobalKeyListener *listener = GlobalKeyListener::instance();

  switch (event->type) {
    case EVENT_KEY_PRESSED:
      emit listener->keyPressed(UioHookKeyToQt(event->data.keyboard.keycode));
      qDebug() << QString("GlobalKeyPress keycode=%1, rawcode=%2")
                    .arg(event->data.keyboard.keycode)
                    .arg(event->data.keyboard.rawcode);
      break;

    case EVENT_KEY_RELEASED:
      emit listener->keyReleased(UioHookKeyToQt(event->data.keyboard.keycode));
      qDebug() << QString("GlobalKeyRelease keycode=%1, rawcode=%2")
                    .arg(event->data.keyboard.keycode)
                    .arg(event->data.keyboard.rawcode);
      break;

    case EVENT_KEY_TYPED:
      emit listener->keyTyped(UioHookKeyToQt(event->data.keyboard.keycode));
      qDebug() << QString("GlobalKeyType keycode=%1, rawcode=%2")
                    .arg(event->data.keyboard.keycode)
                    .arg(event->data.keyboard.rawcode);
      break;
    default:
      break;
  }
}

GlobalKeyListener::GlobalKeyListener(QObject *parent) : QObject(parent) {
  m_thread = std::make_unique<QThread>();
  moveToThread(m_thread.get());

  hook_set_dispatch_proc(&uiohookEventCallback);

  m_thread->start();
  connect(m_thread.get(), &QThread::started, this, []() { hook_run(); });
}

GlobalKeyListener::~GlobalKeyListener() {
  QMetaObject::invokeMethod(this, &GlobalKeyListener::cleanupImpl);
  m_thread->wait();
}

GlobalKeyListener *GlobalKeyListener::instance() {
  static GlobalKeyListener instance;
  return &instance;
}

void GlobalKeyListener::cleanup() {
  QMetaObject::invokeMethod(this, &GlobalKeyListener::cleanupImpl);
}

void GlobalKeyListener::cleanupImpl() {
  hook_stop();
  m_thread->quit();
}
