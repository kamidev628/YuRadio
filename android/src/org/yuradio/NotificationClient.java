// Copyright (C) 2021 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

package org.yuradio;

import android.app.Notification;
import android.app.NotificationManager;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.BitmapFactory;
import android.app.NotificationChannel;

public class NotificationClient {
    public static void notify(Context context, String contentTitle, String contentText) {
        try {
            NotificationManager m_notificationManager = (NotificationManager)
                    context.getSystemService(Context.NOTIFICATION_SERVICE);

            Notification.Builder m_builder;
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                int importance = NotificationManager.IMPORTANCE_DEFAULT;
                NotificationChannel notificationChannel;
                notificationChannel = new NotificationChannel("YuRadio", "YuRadio Notifier", importance);
                m_notificationManager.createNotificationChannel(notificationChannel);
                m_builder = new Notification.Builder(context, notificationChannel.getId());
            } else {
                m_builder = new Notification.Builder(context);
            }

            Bitmap icon = BitmapFactory.decodeResource(context.getResources(), R.drawable.shortwave);
            m_builder.setSmallIcon(R.drawable.shortwave)
                    .setLargeIcon(icon)
                    .setContentTitle(contentTitle)
                    .setContentText(contentText)
                    .setDefaults(Notification.DEFAULT_SOUND)
                    .setColor(Color.TRANSPARENT)
                    .setAutoCancel(true);

            m_notificationManager.notify(0, m_builder.build());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
