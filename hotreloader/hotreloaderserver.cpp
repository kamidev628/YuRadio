#include <QLoggingCategory>
Q_LOGGING_CATEGORY(hotreloaderServerLog, "Hotreloader.Server")

#include <QDir>
#include <QFile>
#include <QThread>

#include <QHttpServer>
#include <QWebSocket>
#include <QWebSocketServer>

#include <QCoreApplication>

#include <QDirIterator>
#include <QJsonArray>

#include "hotreloaderserver.h"

using namespace std::chrono_literals;
using namespace Qt::StringLiterals;

HotReloaderServer::HotReloaderServer(quint16 webSocketPort, quint16 httpPort,
                                     QObject *parent)
    : QObject{parent}, m_httpServer(new QHttpServer(this)) {

  m_server = new QWebSocketServer(QStringLiteral("Hotreloader Server"),
                                  QWebSocketServer::NonSecureMode, this);

  m_httpServer->route("/hotreloader/watched/files",
                      [&](const QHttpServerRequest &req) {
    QDir appDir(QCoreApplication::applicationDirPath());

    QStringList filePaths;

    for (const auto &filePath : m_watcher.files()) {
      filePaths << ("/" + appDir.relativeFilePath(filePath));
    }
    return QJsonArray::fromStringList(filePaths);
  });

  m_httpServer->route("/.*", [&](const QHttpServerRequest &req) {
    QString filePath = req.url().path();

    qCInfo(hotreloaderServerLog) << "File requested:" << filePath;
    return QHttpServerResponse::fromFile(filePath.mid(1));
  });

  if (m_httpServer->listen(QHostAddress::Any, httpPort)) {
    qCInfo(hotreloaderServerLog)
      << "Hotreloader Http Server listening on port" << httpPort;
  } else {
    qCWarning(hotreloaderServerLog)
      << "Failed to listen on http port" << httpPort;
  }

  if (m_server->listen(QHostAddress::Any, webSocketPort)) {
    qCInfo(hotreloaderServerLog)
      << "Hotreloader WebSocket Server listening on port" << webSocketPort;

    connect(m_server, &QWebSocketServer::newConnection, this,
            &HotReloaderServer::onNewConnection);

    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this,
            &HotReloaderServer::onDirectoryChanged);
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this,
            &HotReloaderServer::onFileChanged);
  } else {
    qCWarning(hotreloaderServerLog) << m_server->errorString();
  }
}

HotReloaderServer::~HotReloaderServer() {
  qDeleteAll(m_clients);
}

void HotReloaderServer::onNewConnection() {
  QWebSocket *sock = m_server->nextPendingConnection();

  qCInfo(hotreloaderServerLog)
    << "Client connected:" << sock->peerName() << sock->origin();

  connect(sock, &QWebSocket::binaryMessageReceived, this,
          &HotReloaderServer::processMessage);
  connect(sock, &QWebSocket::disconnected, this,
          &HotReloaderServer::socketDisconnected);

  m_clients << sock;
}

void HotReloaderServer::processMessage(const QByteArray &message) {
  qCInfo(hotreloaderServerLog) << "Got client message:" << message;
}

void HotReloaderServer::socketDisconnected() {
  auto *client = qobject_cast<QWebSocket *>(sender());

  if (client) {
    qCInfo(hotreloaderServerLog)
      << "Client disconnected:" << client->peerName() << client->origin();

    m_clients.removeAll(client);
    client->deleteLater();
  }
}

void HotReloaderServer::setWatchDirectory(const QString &path) {
  QDir projectDir = QDir(path);

  if (!projectDir.exists()) {
    qCWarning(hotreloaderServerLog)
      << "Directory " << path << " doesn't exist. Live reload will not work.";
    return;
  }

  qCInfo(hotreloaderServerLog) << "Directory for file watcher set to: " << path;

  m_watchedDir = projectDir;

  addPaths(m_watchedDir);
  m_fileTimers.clear();

  qCInfo(hotreloaderServerLog)
    << "Finished! Number of qml files watched by file watcher: "
    << m_watcher.files().count();
}

void HotReloaderServer::onDirectoryChanged(const QString &path) {
  qCInfo(hotreloaderServerLog) << "Directory changed:" << path;

  m_watcher.removePaths(m_watcher.files());

  addPaths(m_watchedDir);
  m_fileTimers.clear();
}

void HotReloaderServer::onFileChanged(const QString &path) {
  QFileInfo fi(path);

  int maxNumberOfIterations = 20;
  for (int i = 0; i < maxNumberOfIterations && fi.size() <= 0; ++i) {
    QThread::sleep(10ms);
  }

  m_watcher.addPath(path);

  QElapsedTimer &timer = m_fileTimers[path];
  if (!timer.hasExpired(100)) {
    return;
  }

  timer.start();

  qCInfo(hotreloaderServerLog) << "File changed:" << path;

  QString fileName = path.section("/", -1, -1);
  QDirIterator it(QDir::currentPath(), {fileName}, QDir::Files,
                  QDirIterator::Subdirectories);

  while (it.hasNext()) {
    QString nextFile = it.next();
    QFile::remove(nextFile);
    QFile::copy(path, nextFile);
  }

  for (QWebSocket *client : m_clients) {
    /* Notify all clients about file change */
    client->sendBinaryMessage("Notify");
  }
}

void HotReloaderServer::addPaths(const QDir &directory) {
  QStringList qmlFiles = directory.entryList({"*.qml"});
  for (QString &qmlFile : qmlFiles) {
    qmlFile.prepend(directory.absolutePath() + "/");
  }

  if (qmlFiles.count() > 0) {
    m_watcher.addPaths(qmlFiles);
  }

  QStringList directories = directory.entryList(
    {"*"}, QDir::Dirs | QDir::NoSymLinks | QDir::NoDotAndDotDot);

  for (QString &dir : directories) {
    if (!m_ignoreDirs.contains(dir)) {
      dir.prepend(directory.absolutePath() + "/");
      addPaths(QDir(dir));
    }
  }
}

void HotReloaderServer::setIgnoreDirs(const QStringList &ignoreDirs) {
  m_ignoreDirs = ignoreDirs;
}

void HotReloaderServer::setQmlSourceDir(const QString &path) {
  m_qmlSourceDir = path;
}
