#ifndef HOTRELOADERCLIENT_H
#define HOTRELOADERCLIENT_H

#include <QQmlError>
#include <QRect>
#include <QSslError>
#include <QWebSocket>

class QQmlApplicationEngine;
class HotReloaderUrlInterceptor;
class QNetworkAccessManager;

class HotReloaderClient : public QObject {
  Q_OBJECT

public:
  explicit HotReloaderClient(QQmlApplicationEngine *engine, QString host,
                             QString mainPage, QString errorPage,
                             QStringList modules = {},
                             QObject *parent = nullptr);

  void reloadQml();

private slots:
  void onConnected();
  void onMessageReceived(const QByteArray &message);

private:
  QString m_host;

  QRect m_windowRect;
  QList<QQmlError> m_errors;

  QWebSocket m_sock;

  QString m_mainPage;
  QString m_errorPage;
  QString m_currentPage;
  QStringList m_modules;

  QQmlApplicationEngine *m_engine = nullptr;
  HotReloaderUrlInterceptor *m_interceptor = nullptr;
};

#endif /* !HOTRELOADERCLIENT_H */
