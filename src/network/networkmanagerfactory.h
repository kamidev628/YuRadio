#ifndef NETWORKMANAGERFACTORY_H
#define NETWORKMANAGERFACTORY_H

#include <QQmlNetworkAccessManagerFactory>

class NetworkManagerFactory : public QObject,
                              public QQmlNetworkAccessManagerFactory {
  Q_OBJECT

public:
  explicit NetworkManagerFactory(QObject *parent = nullptr);
  QNetworkAccessManager *create(QObject *parent) override;
};

#endif /* !NETWORKMANAGERFACTORY_H */
