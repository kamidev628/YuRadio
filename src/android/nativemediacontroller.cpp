#include <QtCore/private/qandroidextras_p.h>

#include "nativemediacontroller.h"

static const char nativeMediaControllerClassName[] =
  "org/yuradio/NativeMediaController";

NativeMediaController::NativeMediaController(QObject *parent)
    : QObject(parent) {
  m_controller = QJniObject(nativeMediaControllerClassName);

  auto activity = QJniObject(QNativeInterface::QAndroidApplication::context());
  activity.callMethod<void>("registerNativeMediaController",
                            "(Lorg/yuradio/NativeMediaController;)V",
                            m_controller.object());
}

void NativeMediaController::setSource(const QUrl &url) {
  m_controller.callMethod<void>("setSource", url.toString());
}

void NativeMediaController::play() {
  m_controller.callMethod<void>("play");
}

void NativeMediaController::stop() {
  m_controller.callMethod<void>("stop");
}

void NativeMediaController::pause() {
  m_controller.callMethod<void>("pause");
}

void NativeMediaController::setVolume(float volume) {
  m_controller.callMethod<void>("setVolume", volume);
}

NativeMediaController *NativeMediaController::instance() {
  static NativeMediaController mediaController;
  return &mediaController;
}

static void onIsPlayingChangedNative(JNIEnv * /*env*/, jobject /*thiz*/,
                                     jboolean isPlaying) {
  NativeMediaController *controller = NativeMediaController::instance();
  emit controller->isPlayingChanged(isPlaying);
}

Q_DECLARE_JNI_NATIVE_METHOD(onIsPlayingChangedNative);

static void onPlaybackStateChangedNative(JNIEnv * /*env*/, jobject /*thiz*/,
                                         jint playbackState) {
  NativeMediaController *controller = NativeMediaController::instance();
  emit controller->playbackStateChanged(playbackState);
}

Q_DECLARE_JNI_NATIVE_METHOD(onPlaybackStateChangedNative);

static void onMediaTitleChangedNative(JNIEnv *env, jobject /*thiz*/,
                                      jstring title) {
  NativeMediaController *controller = NativeMediaController::instance();
  emit controller->streamTitleChanged(env->GetStringUTFChars(title, nullptr));
}

Q_DECLARE_JNI_NATIVE_METHOD(onMediaTitleChangedNative);

static void onPlayerErrorChangedNative(JNIEnv *env, jobject /*thiz*/,
                                       jint errorCode, jstring message) {
  NativeMediaController *controller = NativeMediaController::instance();
  emit controller->playerErrorChanged(errorCode,
                                      env->GetStringUTFChars(message, nullptr));
}

Q_DECLARE_JNI_NATIVE_METHOD(onPlayerErrorChangedNative);

static void onIsLoadingChangedNative(JNIEnv * /*env*/, jobject /*thiz*/,
                                     jboolean isLoading) {
  NativeMediaController *controller = NativeMediaController::instance();
  emit controller->isLoadingChanged(isLoading);
}

Q_DECLARE_JNI_NATIVE_METHOD(onIsLoadingChangedNative);

void NativeMediaController::registerNativeMethods() {
  std::initializer_list<JNINativeMethod> methods = {
    Q_JNI_NATIVE_METHOD(onIsPlayingChangedNative),
    Q_JNI_NATIVE_METHOD(onPlaybackStateChangedNative),
    Q_JNI_NATIVE_METHOD(onMediaTitleChangedNative),
    Q_JNI_NATIVE_METHOD(onPlayerErrorChangedNative),
    Q_JNI_NATIVE_METHOD(onIsLoadingChangedNative),
  };

  QJniEnvironment env;
  env.registerNativeMethods(nativeMediaControllerClassName, methods);
}
