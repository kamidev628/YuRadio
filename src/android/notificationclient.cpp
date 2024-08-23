#include "notificationclient.h"

#include <QJniObject>
#include <QtCore/private/qandroidextras_p.h>

using namespace Qt::StringLiterals;

NotificationClient::NotificationClient(QObject *parent) : QObject(parent) {
  if (QNativeInterface::QAndroidApplication::sdkVersion() >=
      __ANDROID_API_T__) {
    const auto notificationPermission =
      "android.permission.POST_NOTIFICATIONS"_L1;
    auto requestResult =
      QtAndroidPrivate::requestPermission(notificationPermission);
    if (requestResult.result() != QtAndroidPrivate::Authorized) {
      qWarning() << "Failed to acquire permission to post notifications "
                    "(required for Android 13+)";
    }
  }
}

void NotificationClient::notify(const QString &contentTitle,
                                const QString &contentText) {
  QJniObject javaContentTitle = QJniObject::fromString(contentTitle);
  QJniObject javaContentText = QJniObject::fromString(contentText);
  QJniObject::callStaticMethod<void>(
    "org/yuradio/NotificationClient", "notify",
    "(Landroid/content/Context;Ljava/lang/String;Ljava/lang/String;)V",
    QNativeInterface::QAndroidApplication::context(),
    javaContentTitle.object<jstring>(), javaContentText.object<jstring>());
}
