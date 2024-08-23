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

bool JsonRestListModel::tryParseJsonData(const QByteArray &data) {
  std::optional<QJsonDocument> document = json::byteArrayToJson(data);
  if (!document) {
    return false;
  }

  QJsonArray dataArray;
  QJsonObject rootObj;

  if (document->isObject()) {
    if (m_dataPath.isNull()) {
      qCWarning(yuRestLog)
        << "Received valid Json object, but `data` path is not specified";
      return false;
    }

    rootObj = document->object();
    if (!rootObj[m_dataPath].isArray()) {
      qCWarning(yuRestLog) << "Not valid array at:" << m_dataPath;
      return false;
    }

    dataArray = rootObj[m_dataPath].toArray();

  } else if (document->isArray()) {
    dataArray = document->array();
  } else {
    qCWarning(yuRestLog) << "Invalid Json";
    return false;
  }

  qsizetype sizeBefore = m_items.size();
  QQmlEngine *engine = qmlEngine(this);
  for (const auto &dataObj : std::as_const(dataArray)) {
    int last = rowCount({});

    QJSValue obj = engine->toScriptValue(dataObj.toObject());
    QVariant maybeItem = preprocessItem().call({obj}).toVariant();

    if (!maybeItem.isNull()) {
      if (m_roleNames.isEmpty()) {
        generateRoleNames(maybeItem.toMap());
      }

      beginInsertRows({}, last, last);
      m_items.push_back(maybeItem.toMap());
      endInsertRows();
    }
  }
  if (sizeBefore != m_items.size()) {
    emit countChanged();
  }

  return true;
}

void JsonRestListModel::handleRequestData(const QByteArray &data) {
  if (tryParseJsonData(data)) {
    setStatus(Ready);
  } else {
    setStatus(Error);
  }
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
