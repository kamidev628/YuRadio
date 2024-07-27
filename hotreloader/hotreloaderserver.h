#ifndef HOTRELOADERSERVER_H
#define HOTRELOADERSERVER_H

#include <QDir>
#include <QElapsedTimer>
#include <QFileSystemWatcher>

class QWebSocket;
class QWebSocketServer;
class QHttpServer;

class HotReloaderServer : public QObject {
  Q_OBJECT

public:
  explicit HotReloaderServer(quint16 webSocketPort, quint16 httpPort,
                             QObject *parent = nullptr);
  ~HotReloaderServer() override;

  void setWatchDirectory(const QString &path);
  void setQmlSourceDir(const QString &path);
  void setIgnoreDirs(const QStringList &ignoreDirs);
  void setErrorPage(const QString &errorPage);

signals:
  void reload();

private slots:
  void onDirectoryChanged(const QString &path);
  void onFileChanged(const QString &path);

  void onNewConnection();
  void processMessage(const QByteArray &message);
  void socketDisconnected();

private:
  void addPaths(const QDir &directory);
  void removePreferFromQmldir();

private:
  QWebSocketServer *m_server;
  QHttpServer *m_httpServer;

  QList<QWebSocket *> m_clients;

  QFileSystemWatcher m_watcher;
  QHash<QString, QElapsedTimer> m_fileTimers;

  QStringList m_ignoreDirs;
  QString m_qmlSourceDir;
  QDir m_watchedDir;
};

#endif /* !HOTRELOADERSERVER_H */
