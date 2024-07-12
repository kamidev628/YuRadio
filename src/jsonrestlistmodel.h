#ifndef JSONRESTLISTMODEL_H
#define JSONRESTLISTMODEL_H

#include "abstractrestmodel.h"

class JsonRestListModel : public AbstractRestListModel {
  Q_OBJECT
  Q_PROPERTY(QString dataPath READ dataPath WRITE setDataPath NOTIFY
               dataPathChanged FINAL)
  QML_ELEMENT

public:
  Q_INVOKABLE JsonRestListModel(QObject *parent = nullptr);

  int rowCount(const QModelIndex &parent) const override;
  QVariant data(const QModelIndex &index, int role) const override;

  QHash<int, QByteArray> roleNames() const override;

  Q_INVOKABLE void reset() override;
  Q_INVOKABLE QVariantMap get(int row);

  QString dataPath() const;
  void setDataPath(const QString &newDataPath);

  void generateRoleNames(const QVariantMap &item);

signals:
  void dataPathChanged();
  void fetchMoreRequested();

protected:
  void handleRequestData(const QByteArray &data) override;

private:
  QList<QVariantMap> m_items;

  QHash<int, QByteArray> m_roleNames;
  int m_roleNameIndex;

  QString m_dataPath;
};

#endif /* !JSONRESTLISTMODEL_H */
