#include <QLoggingCategory>
Q_LOGGING_CATEGORY(hotreloaderClientLog, "Hotreloader.Client")

#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlProperty>
#include <QQuickWindow>

#include <QDir>
#include <QDirIterator>

#include <QCoreApplication>

#include "hotreloaderclient.h"
#include "hotreloaderurlinterceptor.h"

using namespace Qt::StringLiterals;

HotReloaderClient::HotReloaderClient(QQmlApplicationEngine *engine,
                                     QString host, QObject *parent)
    : QObject(parent), m_host(std::move(host)), m_modules({"Main"_L1}),
      m_engine(engine) {
  connect(&m_sock, &QWebSocket::connected, this,
          &HotReloaderClient::onConnected);

  QUrl webSocketUrl;
  webSocketUrl.setScheme(QStringLiteral("ws"));
  webSocketUrl.setHost(m_host);
  webSocketUrl.setPort(3030);

  m_sock.open(webSocketUrl);

  m_interceptor = new HotReloaderUrlInterceptor(m_host, this);

  connect(m_engine, &QQmlApplicationEngine::warnings, this,
          [this](auto warnings) { m_errors = warnings; }, Qt::QueuedConnection);

  connect(m_engine, &QQmlApplicationEngine::objectCreated, this,
          [this](QObject *obj, const QUrl & /*url*/) {
    if (obj) {
      auto *window = qobject_cast<QQuickWindow *>(obj);
      if (window && !m_windowRect.isNull()) {
        window->setGeometry(m_windowRect);
      }
      return;
    }

    /* Display error page */
    if (!m_errorPage.isNull()) {
      QString errorString;
      for (auto &error : m_errors) {
        errorString += error.toString() + "\n";
      }

      m_engine->rootContext()->setContextProperty(QStringLiteral("QmlWarnings"),
                                                  errorString);

      if (m_currentPage != m_errorPage) {
        m_currentPage = m_errorPage;
        reloadQml();
      }
    }
  }, Qt::QueuedConnection);
}

void HotReloaderClient::onConnected() {
  qCInfo(hotreloaderClientLog) << "WebSocket connected";

  connect(&m_sock, &QWebSocket::binaryMessageReceived, this,
          &HotReloaderClient::onMessageReceived);

  m_sock.sendBinaryMessage("Hotreloader Client");
}

void HotReloaderClient::onMessageReceived(const QByteArray &message) {
  qCInfo(hotreloaderClientLog)
    << "Client received message from server:" << message;

  m_currentPage = m_mainPage;
  reloadQml();
}

void HotReloaderClient::reloadQml() {
  qCInfo(hotreloaderClientLog) << "Reloading...";

  if (!m_engine->rootObjects().isEmpty()) {
    /* Save window geometry */
    QObject *rootObject = m_engine->rootObjects().first();
    auto *window = qobject_cast<QQuickWindow *>(rootObject);
    if (window) {
      m_windowRect = window->geometry();
    }

    window->deleteLater();
  }

  QUrl pageAddress;

  pageAddress.setScheme(QStringLiteral("http"));
  pageAddress.setHost(m_host);
  pageAddress.setPath(m_currentPage);

  m_engine->clearComponentCache();
  m_engine->load(pageAddress);
}

void HotReloaderClient::setErrorPage(const QString &errorPage) {
  m_errorPage = errorPage;
}

void HotReloaderClient::setMainPage(const QString &mainPage) {
  m_mainPage = mainPage;
  m_currentPage = mainPage;
}

void HotReloaderClient::setModules(const QStringList &modules) {
  m_modules = modules;

  m_interceptor->setModules(modules);
  connect(m_interceptor, &HotReloaderUrlInterceptor::readyIntercept, this,
          [this]() {
    if (!m_engine->urlInterceptors().contains(m_interceptor)) {
      m_engine->addUrlInterceptor(m_interceptor);
    }
  });
}
