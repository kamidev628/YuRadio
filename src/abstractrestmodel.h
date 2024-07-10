#ifndef RESTMODEL_H
#define RESTMODEL_H

#include <QAbstractListModel>

#include "network.h"
#include "restpagination.h"

class NetworkManager;

class AbstractRestListModel : public QAbstractListModel {
  Q_OBJECT

  Q_PROPERTY(QVariantMap filters READ filters WRITE setFilters NOTIFY
               filtersChanged FINAL)
  Q_PROPERTY(RestPagination *pagination READ pagination WRITE setPagination
               NOTIFY paginationChanged FINAL)
  Q_PROPERTY(QString orderByQuery READ orderByQuery WRITE setOrderByQuery NOTIFY
               orderByQueryChanged FINAL)
  Q_PROPERTY(
    QString orderBy READ orderBy WRITE setOrderBy NOTIFY orderByChanged FINAL)
  Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged FINAL)
  Q_PROPERTY(NetworkManager *restManager READ restManager WRITE setRestManager
               NOTIFY restManagerChanged FINAL)

public:
  using QAbstractListModel::QAbstractListModel;
  Q_INVOKABLE void loadPage();

  virtual void handleRequestData(const QByteArray &data) = 0;

  void clearReplies();
  QString errorString() const;

  NetworkManager *restManager() const;
  void setRestManager(NetworkManager *newRestManager);

  QVariantMap filters() const;
  void setFilters(const QVariantMap &newFilters);

  RestPagination *pagination() const;
  void setPagination(RestPagination *newPagination);

  QString orderBy() const;
  void setOrderBy(const QString &newOrderBy);

  QString orderByQuery() const;
  void setOrderByQuery(const QString &newOrderByQuery);

  QString path() const;
  void setPath(const QString &newPath);

signals:
  void pageLoaded();
  void restManagerChanged();
  void filtersChanged();
  void paginationChanged();
  void orderByChanged();
  void orderByQueryChanged();
  void pathChanged();

protected:
  void queryApplyFilters(QUrlQuery &query);

protected:
  NetworkManager *m_networkManager = nullptr;
  RestPagination *m_pagination = nullptr;
  ReplyPointer m_reply = nullptr;

  QUrlQuery m_baseQuery;
  QVariantMap m_filters;
  QString m_orderBy;
  QString m_errorString;

  QString m_orderByQuery;
  QString m_path;
};

#endif /* !RESTMODEL_H */
