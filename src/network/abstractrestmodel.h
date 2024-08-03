#ifndef RESTMODEL_H
#define RESTMODEL_H

#include <QAbstractListModel>
#include <QQmlListProperty>

#include "networkmanager.h"
#include "restpagination.h"

class RestListModelFilter : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString key READ key WRITE setKey NOTIFY keyChanged FINAL)
  Q_PROPERTY(QVariant value READ value WRITE setValue NOTIFY valueChanged FINAL)
  Q_PROPERTY(bool excludeWhenEmpty READ excludeWhenEmpty WRITE
               setExcludeWhenEmpty NOTIFY excludeWhenEmptyChanged FINAL)
  QML_ELEMENT
public:
  RestListModelFilter() = default;

  QString key() const;
  void setKey(const QString &newKey);

  QVariant value() const;
  void setValue(const QVariant &newValue);

  bool excludeWhenEmpty() const;
  void setExcludeWhenEmpty(bool newExcludeWhenEmpty);

signals:
  void keyChanged();
  void valueChanged();

  void excludeWhenEmptyChanged();

private:
  QString m_key;
  QVariant m_value;
  bool m_excludeWhenEmpty = true;
};

class AbstractRestListModel : public QAbstractListModel {
  Q_OBJECT

  Q_PROPERTY(NetworkManager *restManager READ restManager WRITE setRestManager
               NOTIFY restManagerChanged REQUIRED)
  Q_PROPERTY(RestPagination *pagination READ pagination WRITE setPagination
               NOTIFY paginationChanged)
  Q_PROPERTY(int count READ count NOTIFY countChanged FINAL)
  Q_PROPERTY(QQmlListProperty<RestListModelFilter> filters READ filters)
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

public:
  AbstractRestListModel(QObject *parent = nullptr);
  using QAbstractListModel::QAbstractListModel;

  enum Status {
    Null = 0,
    Ready,
    Loading,
    Error,
  };
  Q_ENUM(Status)

  virtual void handleRequestData(const QByteArray &data) = 0;

  Q_INVOKABLE virtual void reset() = 0;
  Q_INVOKABLE void loadPage();
  Q_INVOKABLE void reload();

  int count() const;

  QString errorString() const;

  NetworkManager *restManager() const;
  void setRestManager(NetworkManager *newRestManager);

  QQmlListProperty<RestListModelFilter> filters();
  void appendFilter(RestListModelFilter *filter);
  void clearFilter();

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
  QUrlQuery queryWithFilters() const;
  bool tryAddFilter(QUrlQuery &query, const QString &key,
                    const QVariant &value) const;

  static void appendFilter(QQmlListProperty<RestListModelFilter> *propertyList,
                           RestListModelFilter *filter);
  static void clearFilter(QQmlListProperty<RestListModelFilter> *propertyList);

signals:
  void restManagerChanged();
  void countChanged();
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
  QList<RestListModelFilter *> m_filters;
  QString m_orderBy;
  QString m_errorString;

  QString m_orderByQuery;
  QString m_path;

  mutable QJSValue m_fetchMoreHandler;
  mutable QJSValue m_preprocessItem;

  Status m_status;
};

#endif /* !RESTMODEL_H */
