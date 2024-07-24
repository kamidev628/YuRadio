// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

#ifndef NOTIFICATIONCLIENT_H
#define NOTIFICATIONCLIENT_H

#include <QObject>

//! [Qt Notification Class]
class NotificationClient : public QObject {
  Q_OBJECT
public:
  explicit NotificationClient(QObject *parent = 0);

  Q_INVOKABLE void setNotification(const QString &notification);
  Q_INVOKABLE QString notification() const;

signals:
  void notificationChanged();

private slots:
  void updateAndroidNotification();

private:
  QString m_notification;
};
//! [Qt Notification Class]
#endif // NOTIFICATIONCLIENT_H
