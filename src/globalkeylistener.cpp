#include <QLoggingCategory>
Q_LOGGING_CATEGORY(globalKeyListenerLog, "YuRadio.GlobalKeyListener")

#include <QQmlInfo>
#include <QThread>

#include "globalkeylistener.h"

#ifdef UIOHOOK_SUPPORTED
#include <uiohook.h>

using namespace Qt::StringLiterals;

Q_GLOBAL_STATIC(GlobalKeyListener, g_keyListener);

static inline Qt::Key UioHookKeyToQt(uint16_t keycode) {
  switch (keycode) {
    /* TODO: Add supported keys */
    case VC_Y:
      return Qt::Key_Y;
    case VC_U:
      return Qt::Key_U;
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

static inline Qt::KeyboardModifiers UioHookModifierToQt(uint16_t modifiers) {
  Qt::KeyboardModifiers qtModifiers = Qt::NoModifier;

  const auto convert_modifier = [&](int uiohookMask,
                                    Qt::KeyboardModifier qtModifier) {
    if (modifiers & uiohookMask) {
      qtModifiers |= qtModifier;
    }
  };

  convert_modifier(MASK_SHIFT, Qt::ShiftModifier);
  convert_modifier(MASK_CTRL, Qt::ControlModifier);
  convert_modifier(MASK_META, Qt::MetaModifier);
  convert_modifier(MASK_ALT, Qt::AltModifier);
  convert_modifier(MASK_NUM_LOCK, Qt::KeypadModifier);

  return qtModifiers;
}

static void uiohookEventCallback(uiohook_event *const event) {
  keyboard_event_data &keyboard = event->data.keyboard;

  switch (event->type) {
    case EVENT_KEY_PRESSED:
      emit g_keyListener->keyPressed(UioHookKeyToQt(keyboard.keycode),
                                     UioHookModifierToQt(event->mask));
      qCInfo(globalKeyListenerLog)
        << QString("GlobalKeyPress keycode=%1, rawcode=%2")
             .arg(keyboard.keycode)
             .arg(keyboard.rawcode);
      break;

    case EVENT_KEY_RELEASED:
      emit g_keyListener->keyReleased(UioHookKeyToQt(keyboard.keycode),
                                      UioHookModifierToQt(event->mask));
      qCInfo(globalKeyListenerLog)
        << QString("GlobalKeyRelease keycode=%1, rawcode=%2")
             .arg(keyboard.keycode)
             .arg(keyboard.rawcode);
      break;

    case EVENT_KEY_TYPED:
      emit g_keyListener->keyTyped(UioHookKeyToQt(keyboard.keycode),
                                   UioHookModifierToQt(event->mask));
      qCInfo(globalKeyListenerLog)
        << QString("GlobalKeyType keycode=%1, rawcode=%2")
             .arg(keyboard.keycode)
             .arg(keyboard.rawcode);
      break;
    default:
      break;
  }
}

GlobalKeyListener::GlobalKeyListener() : QObject(nullptr) {
  m_thread = std::make_unique<QThread>();
  connect(m_thread.get(), &QThread::started, this, &GlobalKeyListener::start);

  m_thread->setObjectName("GlobalKeyListener Thread"_L1);

  moveToThread(m_thread.get());

  hook_set_dispatch_proc(&uiohookEventCallback);

  m_thread->start();
}

GlobalKeyListener *GlobalKeyListener::instance() {
  return g_keyListener;
}

GlobalKeyListener::~GlobalKeyListener() {
  cleanup();
}

void GlobalKeyListener::cleanup() {
  int status = hook_stop();

  switch (status) {
    case UIOHOOK_SUCCESS:
      qCInfo(globalKeyListenerLog) << "Exited successfully";
      break;
    case UIOHOOK_ERROR_OUT_OF_MEMORY:
      qCWarning(globalKeyListenerLog) << "Failed to allocate memory";
      break;
    case UIOHOOK_ERROR_X_RECORD_GET_CONTEXT:
      qCWarning(globalKeyListenerLog) << "Failed to get XRecord context";
      break;
    case UIOHOOK_FAILURE:
    default:
      qCWarning(globalKeyListenerLog) << "An unknown hook error occurred";
      break;
  }

  m_thread->quit();
  m_thread->wait();
}

void GlobalKeyListener::start() {
  int status = hook_run();

  switch (status) {
    case UIOHOOK_SUCCESS:
      break;

    // System level errors.
    case UIOHOOK_ERROR_OUT_OF_MEMORY:
      qWarning(globalKeyListenerLog) << "Failed to allocate memory";
      break;

    // X11 specific errors.
    case UIOHOOK_ERROR_X_OPEN_DISPLAY:
      qWarning(globalKeyListenerLog) << "Failed to open X11 display";
      break;

    case UIOHOOK_ERROR_X_RECORD_NOT_FOUND:
      qWarning(globalKeyListenerLog) << "Unable to locate XRecord extension";
      break;

    case UIOHOOK_ERROR_X_RECORD_ALLOC_RANGE:
      qWarning(globalKeyListenerLog) << "Unable to allocate XRecord range";
      break;

    case UIOHOOK_ERROR_X_RECORD_CREATE_CONTEXT:
      qWarning(globalKeyListenerLog) << "Unable to allocate XRecord context";
      break;

    case UIOHOOK_ERROR_X_RECORD_ENABLE_CONTEXT:
      qWarning(globalKeyListenerLog) << "Failed to enable XRecord context";
      break;

    // Windows specific errors.
    case UIOHOOK_ERROR_SET_WINDOWS_HOOK_EX:
      qWarning(globalKeyListenerLog) << "Failed to register low level windows "
                                        "hook";
      break;

    // Darwin specific errors.
    case UIOHOOK_ERROR_AXAPI_DISABLED:
      qWarning(globalKeyListenerLog)
        << "Failed to enable access for assistive devices";
      break;

    case UIOHOOK_ERROR_CREATE_EVENT_PORT:
      qWarning(globalKeyListenerLog) << "Failed to create apple event port";
      break;

    case UIOHOOK_ERROR_CREATE_RUN_LOOP_SOURCE:
      qWarning(globalKeyListenerLog)
        << "Failed to create apple run loop source";
      break;

    case UIOHOOK_ERROR_GET_RUNLOOP:
      qWarning(globalKeyListenerLog) << "Failed to acquire apple run loop";
      break;

    case UIOHOOK_ERROR_CREATE_OBSERVER:
      qWarning(globalKeyListenerLog)
        << "Failed to create apple run loop observer";
      break;

    case UIOHOOK_FAILURE:
    default:
      qWarning(globalKeyListenerLog) << "An unknown hook error occurred";
      break;
  }
}

GlobalShortcut::GlobalShortcut(QObject *parent)
    : QObject(parent), m_enabled(true) {
  connect(g_keyListener, &GlobalKeyListener::keyPressed, this,
          [this](Qt::Key key, Qt::KeyboardModifiers modifiers) {
    if (m_enabled && m_sequence.matches(QKeyCombination(modifiers, key))) {
      emit activated();
    }
  });
}

static QKeySequence valueToKeySequence(const QVariant &value,
                                       const GlobalShortcut *const shortcut) {
  if (value.userType() == QMetaType::Int) {
    const QVector<QKeySequence> s = QKeySequence::keyBindings(
      static_cast<QKeySequence::StandardKey>(value.toInt()));
    if (s.size() > 1) {
      const QString templateString = QString::fromUtf16(
        u"Shortcut: Only binding to one of multiple key bindings associated "
        u"with %1.");
      qmlWarning(shortcut) << templateString.arg(
        static_cast<QKeySequence::StandardKey>(value.toInt()));
    }
    return s.size() > 0 ? s[0] : QKeySequence{};
  }

  return QKeySequence::fromString(value.toString());
}

QVariant GlobalShortcut::sequence() const {
  return m_sequence;
}

void GlobalShortcut::setSequence(const QVariant &sequence) {
  QKeySequence keySequence = valueToKeySequence(sequence, this);

  if (m_sequence != keySequence) {
    m_sequence = keySequence;
    emit sequenceChanged();
  }
}

bool GlobalShortcut::isEnabled() const {
  return m_enabled;
}

void GlobalShortcut::setEnabled(bool enabled) {
  if (m_enabled != enabled) {
    m_enabled = enabled;
    emit enabledChanged();
  }
}

#else

GlobalShortcut::GlobalShortcut(QObject *parent) : QObject(parent) {}

QVariant GlobalShortcut::sequence() const {
  return {};
}

void GlobalShortcut::setSequence(const QVariant &sequence) {
  Q_UNUSED(sequence)
}

bool GlobalShortcut::isEnabled() const {
  return false;
}

void GlobalShortcut::setEnabled(bool enabled) {
  Q_UNUSED(enabled)
}

#endif /* UIOHOOK_SUPPORTED */
