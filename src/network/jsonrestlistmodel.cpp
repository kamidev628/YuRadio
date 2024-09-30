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

std::optional<QJsonArray>
JsonRestListModel::parseJson(const QByteArray &data, const QString &dataPath) {
  std::optional<QJsonDocument> document = json::byteArrayToJson(data);
  if (!document) {
    return {};
  }

  QJsonArray dataArray;
  QJsonObject rootObj;

  if (document->isObject()) {
    if (dataPath.isNull()) {
      qCWarning(yuRestLog)
        << "Received valid JSON object, but `data` path is not specified";
      return {};
    }

    rootObj = document->object();
    if (!rootObj[dataPath].isArray()) {
      qCWarning(yuRestLog) << "Not valid array at:" << dataPath;
      return {};
    }

    dataArray = rootObj[dataPath].toArray();

  } else if (document->isArray()) {
    dataArray = document->array();

    if (!dataPath.isNull()) {
      qCWarning(yuRestLog)
        << "Received valid JSON array. `dataPath` is redundant";
    }
  } else {
    qCWarning(yuRestLog) << "Invalid Json";
    return {};
  }

  return dataArray;
}

bool JsonRestListModel::tryParseJsonData(const QByteArray &data) {
  auto maybeJsonArray = parseJson(data, m_dataPath);
  if (!maybeJsonArray) {
    return false;
  }

  QQmlEngine *engine = qmlEngine(this);
  Q_ASSERT(engine != nullptr);

  for (const auto &dataObj : std::as_const(*maybeJsonArray)) {
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

  return true;
}

void JsonRestListModel::handleRequestData(const QByteArray &data) {
  if (tryParseJsonData(data)) {
    endHandleRequestData(Ready);
  } else {
    endHandleRequestData(Error);
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
  beginResetRestModel();

  m_items.clear();
  m_roleNames.clear();

  endResetRestModel();
}

QVariantMap JsonRestListModel::get(int row) {
  if (row < 0 || row >= rowCount({})) {
    return {};
  }

  return m_items.at(row);
}
