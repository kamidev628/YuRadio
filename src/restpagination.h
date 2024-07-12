#ifndef RESTPAGINATION_H
#define RESTPAGINATION_H

#include <QObject>
#include <QtQmlIntegration>

class RestPagination : public QObject {
  Q_OBJECT
  Q_PROPERTY(
    int totalCount READ totalCount WRITE setTotalCount NOTIFY totalCountChanged)
  QML_INTERFACE

public:
  explicit RestPagination(QObject *parent = nullptr);

  virtual QHash<QString, QString> queryParams() const = 0;
  virtual bool canFetchMore() = 0;

  Q_INVOKABLE virtual void nextPage() = 0;
  Q_INVOKABLE virtual void prevPage() = 0;

  Q_INVOKABLE virtual bool hasNextPage() = 0;

  int totalCount() const;

signals:
  void totalCountChanged();

public slots:
  void setTotalCount(int totalCount);

protected:
  int m_totalCount;
};

#endif /* !RESTPAGINATION_H */
