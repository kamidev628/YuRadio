#ifndef NOTIFICATIONCLIENT_H
#define NOTIFICATIONCLIENT_H

#include <QObject>
#include <QtQmlIntegration>

class NotificationClient : public QObject {
  Q_OBJECT

public:
  explicit NotificationClient(QObject *parent = nullptr);

public slots:
  void notify(const QString &contentTitle, const QString &contentText);
};

#endif  // NOTIFICATIONCLIENT_H
