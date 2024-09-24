#ifndef RADIOSTATION_H
#define RADIOSTATION_H

#include <QQmlEngine>
#include <QtQmlIntegration>

class RadioStation {
  Q_GADGET
  Q_PROPERTY(QStringList tags MEMBER tags)
  Q_PROPERTY(QString country MEMBER country)
  Q_PROPERTY(QString countryCode MEMBER countryCode)
  Q_PROPERTY(QString state MEMBER state)
  Q_PROPERTY(QString uuid MEMBER uuid)
  Q_PROPERTY(QString name MEMBER name)
  Q_PROPERTY(QString codec MEMBER codec)
  Q_PROPERTY(QString language MEMBER language)
  Q_PROPERTY(QUrl url MEMBER url)
  Q_PROPERTY(QUrl homepage MEMBER homepage)
  Q_PROPERTY(QUrl favicon MEMBER favicon)
  Q_PROPERTY(int votes MEMBER votes)
  Q_PROPERTY(int bitrate MEMBER bitrate)
  Q_PROPERTY(qreal geoLatitude MEMBER geoLatitude)
  Q_PROPERTY(qreal geoLongitude MEMBER geoLongitude)
  QML_VALUE_TYPE(radiostation)

public:
  RadioStation();

  static RadioStation fromJson(const QJsonObject &json);
  Q_INVOKABLE QJsonDocument toJson() const;
  Q_INVOKABLE bool isValid() const;

public:
  QStringList tags;

  QString country;
  QString countryCode;
  QString state;
  QString language;
  QString uuid;
  QString name;
  QString codec;

  QUrl url;
  QUrl homepage;
  QUrl favicon;

  qreal geoLatitude;
  qreal geoLongitude;

  int votes;
  int bitrate;
};

class RadioStationFactory : public QObject {
  Q_OBJECT
  QML_SINGLETON
  QML_ELEMENT

public:
  explicit RadioStationFactory(QObject *parent = nullptr) : QObject(parent) {}

  Q_INVOKABLE static RadioStation create() { return {}; }

  Q_INVOKABLE static RadioStation fromJson(const QJsonObject &json) {
    return RadioStation::fromJson(json);
  }
};

#endif /* !RADIOSTATION_H */
