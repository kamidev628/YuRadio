#ifndef HOTRELOADERURLINTERCEPTOR
#define HOTRELOADERURLINTERCEPTOR

#include <QHash>
#include <QObject>
#include <QQmlAbstractUrlInterceptor>

class QNetworkAccessManager;

class HotReloaderUrlInterceptor : public QObject,
                                  public QQmlAbstractUrlInterceptor {
  Q_OBJECT

public:
  HotReloaderUrlInterceptor(QString host, QObject *parent = nullptr);

  void setModules(const QStringList &modules);
  QUrl intercept(const QUrl &path, DataType /*type*/) override;

signals:
  void readyIntercept();

private:
  QString m_host;
  QStringList m_modules;

  QNetworkAccessManager *m_networkManager = nullptr;
  QHash<QString, QString> m_cachedFilePaths;
};

#endif /* !HOTRELOADERURLINTERCEPTOR */
