#ifndef NETWORKMANAGERFACTORY_H
#define NETWORKMANAGERFACTORY_H

#include <QQmlNetworkAccessManagerFactory>

class NetworkManagerFactory : public QQmlNetworkAccessManagerFactory {
public:
  QNetworkAccessManager *create(QObject *parent) override;
};

#endif /* !NETWORKMANAGERFACTORY_H */
