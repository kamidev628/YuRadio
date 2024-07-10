#ifndef JSONRESTLISTMODEL_H
#define JSONRESTLISTMODEL_H

#include "abstractrestmodel.h"

class JsonRestListModel : public AbstractRestListModel {
  Q_OBJECT

  Q_PROPERTY(QString dataPath READ dataPath WRITE setDataPath NOTIFY
               dataPathChanged FINAL)
  Q_PROPERTY(QJSValue preprocessItem READ preprocessItem WRITE setPreprocessItem
               NOTIFY preprocessItemChanged FINAL)
  Q_PROPERTY(QJSValue fetchMoreHandler READ fetchMoreHandler WRITE
               setFetchMoreHandler NOTIFY fetchMoreHandlerChanged FINAL)

  QML_ELEMENT

public:
  Q_INVOKABLE JsonRestListModel(QObject *parent = nullptr);

  int rowCount(const QModelIndex &parent) const override;
  QVariant data(const QModelIndex &index, int role) const override;

  QHash<int, QByteArray> roleNames() const override;

  Q_INVOKABLE void reset();
  Q_INVOKABLE QVariantMap get(int row);

  bool canFetchMore(const QModelIndex &parent) const override;
  void fetchMore(const QModelIndex &parent) override;

  QString dataPath() const;
  void setDataPath(const QString &newDataPath);

  void generateRoleNames();

  QJSValue preprocessItem() const;
  void setPreprocessItem(const QJSValue &newPreprocessItem);

  QJSValue fetchMoreHandler() const;
  void setFetchMoreHandler(const QJSValue &newFetchMoreHandler);

signals:
  void dataPathChanged();
  void fetchMoreRequested();

  void preprocessItemChanged();
  void fetchMoreHandlerChanged();

protected:
  void handleRequestData(const QByteArray &data) override;

private:
  QList<QVariantMap> m_items;

  QHash<int, QByteArray> m_roleNames;
  int m_roleNameIndex;

  QString m_dataPath;
  mutable QJSValue m_preprocessItem;
  mutable QJSValue m_fetchMoreHandler;
};

#endif /* !JSONRESTLISTMODEL_H */
