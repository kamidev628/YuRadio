#include "jsonrestlistmodel.h"

#include "json.h"
#include "modelhelper.h"

JsonRestListModel::JsonRestListModel(QObject *parent)
    : AbstractRestListModel(parent), m_roleNameIndex(Qt::UserRole + 1) {}

QString JsonRestListModel::dataPath() const {
  return m_dataPath;
}

void JsonRestListModel::setDataPath(const QString &newDataPath) {
  if (m_dataPath == newDataPath) {
    return;
  }

  m_dataPath = newDataPath;
  emit dataPathChanged();
}

void JsonRestListModel::handleRequestData(const QByteArray &data) {
  auto scopeGuard = qScopeGuard([this]() {
    if (status() != Ready) {
      setStatus(Error);
    }
  });

  std::optional<QJsonDocument> document = json::byteArrayToJson(data);
  if (!document) {
    return;
  }

  QJsonArray dataArray;
  QJsonObject rootObj;

  if (document->isObject()) {
    if (m_dataPath.isNull()) {
      qWarning()
        << "Received valid Json object, but `data` path is not specified";
      return;
    }

    rootObj = document->object();
    if (!rootObj[m_dataPath].isArray()) {
      qWarning() << "Not valid array at:" << m_dataPath;
      return;
    }

    dataArray = rootObj[m_dataPath].toArray();

  } else if (document->isArray()) {
    dataArray = document->array();
  } else {
    qWarning() << "Invalid Json";
    return;
  }

  for (const auto &dataObj : std::as_const(dataArray)) {
    int last = rowCount({});

    beginInsertRows({}, last, last);

    QQmlEngine *engine = qmlEngine(this);
    QJSValue obj =
      engine->toScriptValue<QVariantMap>(dataObj.toObject().toVariantMap());

    QVariantMap item = preprocessItem().call({obj}).toVariant().toMap();
    m_items.push_back(std::move(item));

    endInsertRows();
  }

  if (m_roleNames.isEmpty()) {
    generateRoleNames();
  }

  setStatus(Ready);
}

QHash<int, QByteArray> JsonRestListModel::roleNames() const {
  return m_roleNames;
}

void JsonRestListModel::generateRoleNames() {
  m_roleNames.clear();
  m_roleNameIndex = Qt::UserRole + 1;

  if (m_items.isEmpty()) {
    return;
  }

  QVariantMap item = m_items.first();

  for (const auto &[key, value] : item.asKeyValueRange()) {
    m_roleNames[m_roleNameIndex++] = key.toUtf8();
  }
}

QVariant JsonRestListModel::data(const QModelIndex &index, int role) const {
  CHECK_DATA(index);

  const auto &item = m_items.at(index.row());
  return item.value(m_roleNames[role]);
}

int JsonRestListModel::rowCount(const QModelIndex &parent) const {
  CHECK_ROWCOUNT(parent);

  return static_cast<int>(m_items.size());
}

void JsonRestListModel::reset() {
  beginResetModel();

  m_items.clear();
  m_roleNames.clear();

  resetRestModel();

  endResetModel();
}

QVariantMap JsonRestListModel::get(int row) {
  Q_ASSERT(row >= 0);
  Q_ASSERT(row < rowCount({}));

  return m_items.at(row);
}
