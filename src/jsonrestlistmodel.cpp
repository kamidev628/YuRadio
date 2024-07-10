#include "jsonrestlistmodel.h"

#include "restpagination.h"

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

QString AbstractRestListModel::orderByQuery() const {
  return m_orderByQuery;
}

void AbstractRestListModel::setOrderByQuery(const QString &newOrderByQuery) {
  if (m_orderByQuery == newOrderByQuery) {
    return;
  }

  m_orderByQuery = newOrderByQuery;
  emit orderByQueryChanged();
}

QString AbstractRestListModel::path() const {
  return m_path;
}

void AbstractRestListModel::setPath(const QString &newPath) {
  if (m_path == newPath) {
    return;
  }

  m_path = newPath;
  emit pathChanged();
}

QString AbstractRestListModel::errorString() const {
  return m_errorString;
}

bool JsonRestListModel::canFetchMore(const QModelIndex &parent) const {
  CHECK_CANFETCHMORE(parent);

  return m_pagination->canFetchMore();
}

void JsonRestListModel::fetchMore(const QModelIndex &parent) {
  CHECK_FETCHMORE(parent);

  if (!canFetchMore(parent)) {
    return;
  }

  fetchMoreHandler().call();
}

void JsonRestListModel::reset() {
  beginResetModel();

  m_items.clear();
  m_roleNames.clear();

  clearReplies();

  endResetModel();
}

QJSValue JsonRestListModel::preprocessItem() const {
  if (!m_preprocessItem.isCallable()) {
    QQmlEngine *engine = qmlEngine(this);
    if (engine) {
      m_preprocessItem =
        engine->evaluate(QStringLiteral("function(obj) { return obj; }"));
    }
  }

  return m_preprocessItem;
}

void JsonRestListModel::setPreprocessItem(const QJSValue &newPreprocessItem) {
  if (!newPreprocessItem.isCallable()) {
    qmlInfo(this) << "preprocessItem must be a callable function";
    return;
  }

  m_preprocessItem = newPreprocessItem;
  emit preprocessItemChanged();
}

QJSValue JsonRestListModel::fetchMoreHandler() const {
  if (!m_fetchMoreHandler.isCallable()) {
    QQmlEngine *engine = qmlEngine(this);
    if (engine) {
      m_fetchMoreHandler = engine->evaluate(QStringLiteral("function() {}"));
    }
  }

  return m_fetchMoreHandler;
}

void JsonRestListModel::setFetchMoreHandler(
  const QJSValue &newFetchMoreHandler) {
  if (!newFetchMoreHandler.isCallable()) {
    qmlInfo(this) << "fetchMoreHandler must be a callable function";
    return;
  }

  m_fetchMoreHandler = newFetchMoreHandler;
  emit fetchMoreHandlerChanged();
}

QVariantMap JsonRestListModel::get(int row) {
  Q_ASSERT(row >= 0);
  Q_ASSERT(row < rowCount({}));

  return m_items.at(row);
}
