#include <QLoggingCategory>
Q_DECLARE_LOGGING_CATEGORY(yuRestLog);

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
      qCWarning(yuRestLog)
        << "Received valid Json object, but `data` path is not specified";
      return;
    }

    rootObj = document->object();
    if (!rootObj[m_dataPath].isArray()) {
      qCWarning(yuRestLog) << "Not valid array at:" << m_dataPath;
      return;
    }

    dataArray = rootObj[m_dataPath].toArray();

  } else if (document->isArray()) {
    dataArray = document->array();
  } else {
    qCWarning(yuRestLog) << "Invalid Json";
    return;
  }

  QQmlEngine *engine = qmlEngine(this);
  if (m_roleNames.isEmpty() && !dataArray.isEmpty()) {
    QJsonObject firstObject = dataArray.first().toObject();

    QJSValue obj = engine->toScriptValue(firstObject);
    QVariant maybeItem = preprocessItem().call({obj}).toVariant();

    generateRoleNames(maybeItem.toMap());
  }

  for (const auto &dataObj : std::as_const(dataArray)) {
    int last = rowCount({});

    QJSValue obj = engine->toScriptValue(dataObj.toObject());
    QVariant maybeItem = preprocessItem().call({obj}).toVariant();

    if (!maybeItem.isNull()) {
      beginInsertRows({}, last, last);
      m_items.push_back(maybeItem.toMap());
      endInsertRows();
    }
  }

  setStatus(Ready);
}

QHash<int, QByteArray> JsonRestListModel::roleNames() const {
  return m_roleNames;
}

void JsonRestListModel::generateRoleNames(const QVariantMap &item) {
  m_roleNames.clear();
  m_roleNameIndex = Qt::UserRole + 1;

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
  if (row < 0 || row >= rowCount({})) {
    return {};
  }

  return m_items.at(row);
}
