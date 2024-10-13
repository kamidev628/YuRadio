#include <QLoggingCategory>
Q_LOGGING_CATEGORY(storageLog, "YuRadio.Storage")

#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>

#include "network/json.h"
#include "storage.h"

using namespace Qt::StringLiterals;

Storage::Storage(QObject *parent) : QObject(parent) {
  QSqlDatabase database = QSqlDatabase::addDatabase("QSQLITE");
  if (!database.isValid()) {
    qCWarning(storageLog) << "Database is not valid:" << database.lastError();
    return;
  }

  /* Create AppDataLocation if not exists */
  QDir().mkpath(
    QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));

  QDir appDataLocation(
    QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));

  database.setDatabaseName(appDataLocation.filePath(u"YuRadio.db"_s));
  if (!database.open()) {
    qCWarning(storageLog) << "Failed to open Database:" << database.lastError();
    return;
  }

  database.transaction();

  QSqlQuery query;
  query.exec(R"(
CREATE TABLE IF NOT EXISTS bookmark (
    stationuuid TEXT PRIMARY KEY,
    object TEXT
))");
  query.exec(R"(
CREATE TABLE IF NOT EXISTS vote (
    stationuuid TEXT PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
))");
  query.exec(R"(
CREATE TABLE IF NOT EXISTS language (
    language_id INTEGER PRIMARY KEY,
    name TEXT UNIQUE
))");
  query.exec(R"(
CREATE TABLE IF NOT EXISTS country (
    country_id INTEGER PRIMARY KEY,
    name TEXT UNIQUE
))");
  query.exec(R"(
CREATE TABLE IF NOT EXISTS tag (
    tag_id INTEGER PRIMARY KEY, 
    name TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
))");
  query.exec(R"(
CREATE TABLE IF NOT EXISTS track_history (
    track_history_id INTEGER PRIMARY KEY, 
    track_name TEXT,
    station_name TEXT,
    station_image_url TEXT,
    started_at TIMESTAMP,
    ended_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
))");
  query.exec(R"(
CREATE TRIGGER IF NOT EXISTS track_history_insert_trig AFTER INSERT ON track_history
BEGIN
    DELETE FROM track_history WHERE ROWID NOT IN 
        (SELECT ROWID FROM track_history ORDER BY datetime(started_at) DESC LIMIT 1000);
END)");

  database.commit();
}

bool Storage::addBookmark(const RadioStation &station) {
  QSqlQuery query;
  query.prepare("INSERT INTO bookmark (stationuuid, object) VALUES (?, ?)");
  query.addBindValue(station.uuid);
  query.addBindValue(station.toJson().toJson(QJsonDocument::Compact));
  return query.exec();
}

bool Storage::existsBookmark(const QString &uuid) {
  QSqlQuery query;
  query.prepare("SELECT 1 FROM bookmark WHERE stationuuid = ?");
  query.addBindValue(uuid);
  return query.exec() && query.next();
}

QList<RadioStation> Storage::getBookmarks() {
  QSqlQuery query;
  query.exec("SELECT object FROM bookmark");

  QList<RadioStation> result;
  while (query.next()) {
    QByteArray object = query.value(0).toByteArray();

    auto doc = json::byteArrayToJson(object);
    if (!doc) {
      continue;
    }
    result.append(RadioStation::fromJson(doc->object()));
  }

  return result;
}

bool Storage::deleteBookmark(const QString &uuid) {
  QSqlQuery query;
  query.prepare("DELETE FROM bookmark WHERE stationuuid = ?");
  query.addBindValue(uuid);
  return query.exec();
}

bool Storage::addVote(const QString &uuid) {
  QSqlQuery query;
  query.prepare("INSERT INTO vote (stationuuid) VALUES (?)");
  query.addBindValue(uuid);
  return query.exec();
}

bool Storage::existsVote(const QString &uuid) {
  QSqlQuery query;
  query.prepare("SELECT 1 FROM vote WHERE stationuuid = ?");
  query.addBindValue(uuid);
  return query.exec() && query.next();
}

bool Storage::removeExpiredVotes(int interval) {
  QSqlQuery query;
  query.prepare("DELETE FROM vote WHERE strftime('%s', 'now') - strftime('%s', "
                "created_at) >= ?");
  query.addBindValue(interval / 1000);
  return query.exec();
}

bool Storage::removeExpiredTags(int interval) {
  QSqlQuery query;
  query.prepare("DELETE FROM tag WHERE strftime('%s', 'now') - strftime('%s', "
                "created_at) >= ?");
  query.addBindValue(interval / 1000);
  return query.exec();
}

bool Storage::addCountries(const QStringList &countries) {
  QSqlDatabase::database().transaction();

  QSqlQuery query;
  query.prepare("INSERT OR IGNORE INTO country (name) VALUES (?)");

  for (const QString &country : countries) {
    query.bindValue(0, country);
    query.exec();
  }

  return QSqlDatabase::database().commit();
}

QStringList Storage::getCountries() {
  QSqlQuery query;
  query.exec("SELECT name FROM country");

  QStringList countries;
  while (query.next()) {
    countries << query.value(0).toString();
  }
  return countries;
}

bool Storage::addLanguages(const QStringList &languages) {
  QSqlDatabase::database().transaction();

  QSqlQuery query;
  query.prepare("INSERT OR IGNORE INTO language (name) VALUES (?)");

  for (const QString &language : languages) {
    query.bindValue(0, language);
    query.exec();
  }

  return QSqlDatabase::database().commit();
}

QStringList Storage::getLanguages() {
  QSqlQuery query;
  query.exec("SELECT name FROM language ORDER BY language_id");

  QStringList languages;
  while (query.next()) {
    languages << query.value(0).toString();
  }
  return languages;
}

bool Storage::addTags(const QStringList &tags) {
  QSqlDatabase::database().transaction();

  QSqlQuery query;
  query.prepare("INSERT OR IGNORE INTO tag (name) VALUES (?)");

  for (const QString &tag : tags) {
    query.bindValue(0, tag);
    query.exec();
  }

  return QSqlDatabase::database().commit();
}

QStringList Storage::getTags() {
  QSqlQuery query;
  query.exec("SELECT name FROM tag ORDER BY name");

  QStringList tags;
  while (query.next()) {
    tags << query.value(0).toString();
  }
  return tags;
}

bool Storage::addTrackHistory(const QString &trackName,
                              const QString &stationName,
                              const QUrl &stationImageUrl,
                              const QDateTime &startedAt,
                              const QDateTime &endedAt) {
  QSqlQuery query;
  query.prepare("INSERT OR IGNORE INTO track_history (track_name, "
                "station_name, station_image_url, started_at, ended_at) VALUES "
                "(?, ?, ?, ?, ?)");
  query.addBindValue(trackName);
  query.addBindValue(stationName);
  query.addBindValue(stationImageUrl.toString());
  query.addBindValue(startedAt.toString(Qt::ISODate));
  query.addBindValue(endedAt.toString(Qt::ISODate));

  return query.exec();
}
