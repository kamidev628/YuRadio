#ifndef RESTMODEL_H
#define RESTMODEL_H

#include <QAbstractListModel>

#include "network.h"
#include "restpagination.h"

class NetworkManager;

class AbstractRestListModel : public QAbstractListModel {
  Q_OBJECT

  Q_PROPERTY(NetworkManager *restManager READ restManager WRITE setRestManager
               NOTIFY restManagerChanged REQUIRED)
  Q_PROPERTY(RestPagination *pagination READ pagination WRITE setPagination
               NOTIFY paginationChanged)
  Q_PROPERTY(QVariantMap filters READ filters WRITE setFilters NOTIFY
               filtersChanged FINAL)
  Q_PROPERTY(QString orderByQuery READ orderByQuery WRITE setOrderByQuery NOTIFY
               orderByQueryChanged FINAL)
  Q_PROPERTY(
    QString orderBy READ orderBy WRITE setOrderBy NOTIFY orderByChanged FINAL)
  Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged FINAL)
  Q_PROPERTY(QJSValue preprocessItem READ preprocessItem WRITE setPreprocessItem
               NOTIFY preprocessItemChanged FINAL)
  Q_PROPERTY(QJSValue fetchMoreHandler READ fetchMoreHandler WRITE
               setFetchMoreHandler NOTIFY fetchMoreHandlerChanged FINAL)
  Q_PROPERTY(Status status READ status NOTIFY statusChanged FINAL)
  QML_INTERFACE

public:
  AbstractRestListModel(QObject *parent = nullptr);
  using QAbstractListModel::QAbstractListModel;

  enum Status { Null = 0, Ready, Loading, Error };
  Q_ENUM(Status)

  virtual void handleRequestData(const QByteArray &data) = 0;

  Q_INVOKABLE virtual void reset() = 0;
  Q_INVOKABLE void loadPage();

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

  Status status() const;

  QJSValue fetchMoreHandler() const;
  void setFetchMoreHandler(const QJSValue &newFetchMoreHandler);

  QJSValue preprocessItem() const;
  void setPreprocessItem(const QJSValue &newPreprocessItem);

protected:
  bool canFetchMore(const QModelIndex &parent) const override;
  void fetchMore(const QModelIndex &parent) override;

  void setStatus(Status newStatus);
  void resetRestModel();

private:
  QUrlQuery composeQuery() const;

signals:
  void restManagerChanged();
  void filtersChanged();
  void paginationChanged();
  void orderByChanged();
  void orderByQueryChanged();
  void pathChanged();
  void statusChanged();

  void fetchMoreHandlerChanged();
  void preprocessItemChanged();

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

  mutable QJSValue m_fetchMoreHandler;
  mutable QJSValue m_preprocessItem;

  Status m_status;
};

#endif /* !RESTMODEL_H */
