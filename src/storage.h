#ifndef STORAGE_H
#define STORAGE_H

#include <QObject>
#include <QtQmlIntegration>

#include "radiostation.h"

class QSqlDatabase;

class Storage : public QObject {
  Q_OBJECT
  QML_SINGLETON
  QML_ELEMENT

public:
  explicit Storage(QObject *parent = nullptr);

public slots:
  bool addBookmark(const RadioStation &station);
  bool existsBookmark(const QString &uuid);
  QList<RadioStation> getBookmarks();
  bool deleteBookmark(const QString &uuid);

  bool addVote(const QString &uuid);
  bool existsVote(const QString &uuid);

  bool removeExpiredVotes(int interval);
  bool removeExpiredTags(int interval);

  bool addCountries(const QStringList &countries);
  QStringList getCountries();

  bool addLanguages(const QStringList &languages);
  QStringList getLanguages();

  bool addTags(const QStringList &tags);
  QStringList getTags();
};

#endif /* !STORAGE_H */
