#ifndef RESTMODEL_H
#define RESTMODEL_H

#include <QAbstractListModel>
#include <QQmlListProperty>

#include "networkmanager.h"
#include "restpagination.h"

class RestListModelSortFilter : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString key READ key WRITE setKey NOTIFY keyChanged FINAL)
  Q_PROPERTY(QVariant value READ value WRITE setValue NOTIFY valueChanged FINAL)
  Q_PROPERTY(bool excludeWhenEmpty READ excludeWhenEmpty WRITE
               setExcludeWhenEmpty NOTIFY excludeWhenEmptyChanged FINAL)
  QML_ELEMENT
public:
  RestListModelSortFilter() = default;

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
  Q_PROPERTY(QQmlListProperty<RestListModelSortFilter> filters READ filters)
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

  QQmlListProperty<RestListModelSortFilter> filters();
  void appendFilter(RestListModelSortFilter *filter);
  void clearFilter();

  RestPagination *pagination() const;
  void setPagination(RestPagination *newPagination);

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

  static void
  appendFilter(QQmlListProperty<RestListModelSortFilter> *propertyList,
               RestListModelSortFilter *filter);
  static void
  clearFilter(QQmlListProperty<RestListModelSortFilter> *propertyList);

signals:
  void restManagerChanged();
  void countChanged();
  void filtersChanged();
  void paginationChanged();
  void pathChanged();
  void statusChanged();

  void fetchMoreHandlerChanged();
  void preprocessItemChanged();

protected:
  NetworkManager *m_networkManager = nullptr;
  RestPagination *m_pagination = nullptr;
  ReplyPointer m_reply = nullptr;

  QUrlQuery m_baseQuery;
  QList<RestListModelSortFilter *> m_filters;
  QString m_errorString;
  QString m_path;

  mutable QJSValue m_fetchMoreHandler;
  mutable QJSValue m_preprocessItem;

  Status m_status;
};

#endif /* !RESTMODEL_H */
