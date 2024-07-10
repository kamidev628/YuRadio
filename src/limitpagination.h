#ifndef LIMITPAGINATION_H
#define LIMITPAGINATION_H

#include <QtQmlIntegration>

#include "restpagination.h"

class LimitPagination : public RestPagination {
  Q_OBJECT
  Q_PROPERTY(int limit READ limit WRITE setLimit NOTIFY limitChanged)
  Q_PROPERTY(int offset READ offset WRITE setOffset NOTIFY offsetChanged)
  Q_PROPERTY(QString limitQuery READ limitQuery WRITE setLimitQuery NOTIFY
               limitQueryChanged FINAL)
  Q_PROPERTY(QString offsetQuery READ offsetQuery WRITE setOffsetQuery NOTIFY
               offsetQueryChanged FINAL)
  QML_ELEMENT

public:
  Q_INVOKABLE explicit LimitPagination(QObject *parent = nullptr);

  QHash<QString, QString> queryParams() const override;
  void nextPage() override;
  void prevPage() override;
  bool hasNextPage() override;
  bool canFetchMore() override;

  QString limitQuery() const;
  void setLimitQuery(const QString &newLimitQuery);

  QString offsetQuery() const;
  void setOffsetQuery(const QString &newOffsetQuery);

  int limit() const;
  void setLimit(int newLimit);

  int offset() const;
  void setOffset(int newOffset);

signals:
  void limitQueryChanged();
  void offsetQueryChanged();
  void limitChanged();
  void offsetChanged();

private:
  int m_limit;
  int m_offset;
  QString m_limitQuery;
  QString m_offsetQuery;
};

#endif /* !LIMITPAGINATION_H */
