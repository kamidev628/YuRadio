#ifndef PAGEPAGINATION_H
#define PAGEPAGINATION_H

#include <QtQmlIntegration>

#include "restpagination.h"

class PagePagination : public RestPagination {
  Q_OBJECT

  Q_PROPERTY(int perPage READ perPage WRITE setPerPage NOTIFY perPageChanged)
  Q_PROPERTY(int currentPage READ currentPage WRITE setCurrentPage NOTIFY
               currentPageChanged)
  Q_PROPERTY(QString perPageQuery READ perPageQuery WRITE setPerPageQuery NOTIFY
               perPageQueryChanged FINAL)
  Q_PROPERTY(QString currentPageQuery READ currentPageQuery WRITE
               setCurrentPageQuery NOTIFY currentPageQueryChanged FINAL)
  QML_ELEMENT

public:
  Q_INVOKABLE explicit PagePagination(QObject *parent = nullptr);

  int perPage() const;
  int currentPage() const;

  void nextPage() override;
  void prevPage() override;
  QHash<QString, QString> queryParams() const override;

  bool canFetchMore() override;

  QString perPageQuery() const;
  void setPerPageQuery(const QString &newPerPageQuery);

  QString currentPageQuery() const;
  void setCurrentPageQuery(const QString &newCurrentPageQuery);

signals:
  void perPageChanged();
  void currentPageChanged();
  void perPageQueryChanged();
  void currentPageQueryChanged();

public slots:
  void setPerPage(int perPage);
  void setCurrentPage(int currentPage);

private:
  int m_perPage;
  int m_currentPage;
  QString m_perPageQuery;
  QString m_currentPageQuery;
};

#endif /* !PAGEPAGINATION_H */
