#include <QLoggingCategory>
Q_DECLARE_LOGGING_CATEGORY(radioStationModelLog)

#include "radiostation.h"

using namespace Qt::StringLiterals;

RadioStation::RadioStation() = default;

RadioStation RadioStation::fromJson(const QJsonObject &json) {
  RadioStation station;

  station.url = json["url_resolved"_L1].toString();

  if (!station.url.isValid()) {
    station.url = json["url"_L1].toString();
  }

  station.uuid = json["stationuuid"_L1].toString();
  station.bitrate = json["bitrate"_L1].toInt();
  station.favicon = json["favicon"_L1].toString();
  station.homepage = json["homepage"_L1].toString();
  station.state = json["state"_L1].toString();
  station.countryCode = json["countrycode"_L1].toString();
  station.country = json["country"_L1].toString();
  station.tags = json["tags"_L1].toString().trimmed().split(',');

  station.name = json["name"_L1].toString().trimmed();
  station.language = json["language"_L1].toString().trimmed();
  station.codec = json["codec"_L1].toString();
  station.votes = json["votes"_L1].toInt();

  station.geoLatitude = json["geo_lat"_L1].toDouble();
  station.geoLongitude = json["geo_long"_L1].toDouble();

  return station;
}

QJsonDocument RadioStation::toJson() const {
  QJsonObject obj;

  obj["url"] = url.toString();
  obj["url_resolved"] = url.toString();
  obj["stationuuid"] = uuid;
  obj["bitrate"] = bitrate;
  obj["favicon"] = favicon.toString();
  obj["homepage"] = homepage.toString();
  obj["state"] = state;
  obj["countrycode"] = countryCode;
  obj["country"] = country;
  obj["tags"] = tags.join(",");
  obj["name"] = name;
  obj["language"] = language;
  obj["codec"] = codec;
  obj["votes"] = votes;
  obj["geo_lat"] = geoLatitude;
  obj["geo_long"] = geoLongitude;

  return QJsonDocument(obj);
}

bool RadioStation::isValid() const {
  return !uuid.isEmpty() && !name.isEmpty() && url.isValid();
}
