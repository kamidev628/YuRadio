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

  database.setDatabaseName(u"YuRadio"_s);
  if (!database.open()) {
    qCWarning(storageLog) << "Failed to open Database:" << database.lastError();
    return;
  }

  database.transaction();

  QSqlQuery query;
  query.exec(R"(CREATE TABLE IF NOT EXISTS bookmark (
                  stationuuid TEXT PRIMARY KEY,
                  object TEXT
                ))");
  query.exec(R"(CREATE TABLE IF NOT EXISTS vote (
                  stationuuid TEXT PRIMARY KEY,
                  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                ))");
  query.exec(R"(CREATE TABLE IF NOT EXISTS language(name TEXT PRIMARY KEY))");
  query.exec(R"(CREATE TABLE IF NOT EXISTS country(name TEXT PRIMARY KEY))");
  query.exec(R"(CREATE TABLE IF NOT EXISTS tag(
    tag_id INTEGER PRIMARY KEY, name TEXT UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP))");

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
  QSqlQuery query;
  query.prepare("INSERT OR IGNORE INTO country (name) VALUES (?)");

  QVariantList list;
  for (const QString &country : countries) {
    list << country;
  }
  query.addBindValue(list);
  return query.execBatch();
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
  QSqlQuery query;
  query.prepare("INSERT OR IGNORE INTO language (name) VALUES (?)");

  QVariantList list;
  for (const QString &language : languages) {
    list << language;
  }
  query.addBindValue(list);
  return query.execBatch();
}

QStringList Storage::getLanguages() {
  QSqlQuery query;
  query.exec("SELECT name FROM language");

  QStringList languages;
  while (query.next()) {
    languages << query.value(0).toString();
  }
  return languages;
}

bool Storage::addTags(const QStringList &tags) {
  QSqlQuery query;
  query.prepare("INSERT OR IGNORE INTO tag (name) VALUES (?)");

  QVariantList list;
  for (const QString &tag : tags) {
    list << tag;
  }
  query.addBindValue(list);
  return query.execBatch();
}

QStringList Storage::getTags() {
  QSqlQuery query;
  query.exec("SELECT name FROM tag");

  QStringList tags;
  while (query.next()) {
    tags << query.value(0).toString();
  }
  return tags;
}
