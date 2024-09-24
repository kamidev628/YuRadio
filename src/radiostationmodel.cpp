#include <QLoggingCategory>
Q_LOGGING_CATEGORY(radioStationModelLog, "YuRadio.RadioStationModel");

#include "radiostationmodel.h"

#include "network/jsonrestlistmodel.h"
#include "network/modelhelper.h"

using namespace Qt::StringLiterals;

RadioStationModel::RadioStationModel(QObject *parent)
    : AbstractRestListModel(parent) {}

void RadioStationModel::handleRequestData(const QByteArray &data) {
  auto maybeJsonArray = JsonRestListModel::parseJson(data);
  if (!maybeJsonArray) {
    setStatus(Error);
  }

  QQmlEngine *engine = qmlEngine(this);
  Q_ASSERT(engine != nullptr);

  qsizetype sizeBefore = m_stations.size();

  for (const auto &dataObj : std::as_const(*maybeJsonArray)) {
    QJsonObject obj = dataObj.toObject();

    RadioStation station = RadioStation::fromJson(obj);

    if (!station.url.isValid()) {
      qCWarning(radioStationModelLog)
        << QString("Station(%1) doesn't have valid stream url. Skipping...")
             .arg(station.uuid);
      continue;
    }

    int last = rowCount({});
    beginInsertRows({}, last, last);
    m_stations.push_back(std::move(station));
    endInsertRows();
  }

  if (sizeBefore != m_stations.size()) {
    emit countChanged();
  }

  setStatus(Ready);
}

int RadioStationModel::rowCount(const QModelIndex &parent) const {
  CHECK_ROWCOUNT(parent);

  return static_cast<int>(m_stations.size());
}

QVariant RadioStationModel::data(const QModelIndex &index, int role) const {
  CHECK_DATA(index);

  const RadioStation &station = m_stations[index.row()];

  switch (static_cast<Roles>(role)) {
    case UUIDRole:
      return station.uuid;
    case TagsRole:
      return station.tags;
    case CountryRole:
      return station.country;
    case CountryCodeRole:
      return station.countryCode;
    case StateRole:
      return station.state;
    case NameRole:
      return station.name;
    case CodecRole:
      return station.codec;
    case UrlRole:
      return station.url;
    case HomepageRole:
      return station.homepage;
    case FaviconRole:
      return station.favicon;
    case VotesRole:
      return station.votes;
    case BitrateRole:
      return station.bitrate;
    case LanguageRole:
      return station.language;
    case GeoLatitudeRole:
      return station.geoLatitude;
    case GeoLongitudeRole:
      return station.geoLongitude;
  }
}

QHash<int, QByteArray> RadioStationModel::roleNames() const {
  return {{UUIDRole, "uuid"_ba},
          {TagsRole, "tags"_ba},
          {CountryRole, "country"_ba},
          {CountryCodeRole, "countryCode"_ba},
          {StateRole, "state"_ba},
          {NameRole, "name"_ba},
          {CodecRole, "codec"_ba},
          {UrlRole, "url"_ba},
          {HomepageRole, "homepage"_ba},
          {FaviconRole, "favicon"_ba},
          {VotesRole, "votes"_ba},
          {BitrateRole, "bitrate"_ba},
          {LanguageRole, "language"_ba},
          {GeoLatitudeRole, "geoLatitude"_ba},
          {GeoLongitudeRole, "geoLongitude"_ba}};
}

RadioStation RadioStationModel::get(int row) {
  Q_ASSERT(row >= 0);
  Q_ASSERT(row < rowCount({}));

  return m_stations[row];
}

void RadioStationModel::reset() {
  beginResetModel();

  m_stations.clear();
  resetRestModel();

  endResetModel();
}
