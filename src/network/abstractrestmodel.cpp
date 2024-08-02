#include <QLoggingCategory>
Q_LOGGING_CATEGORY(yuRestLog, "YuRest");

#include <QJsonArray>

#include "abstractrestmodel.h"
#include "modelhelper.h"
#include "restpagination.h"

AbstractRestListModel::AbstractRestListModel(QObject *parent)
    : QAbstractListModel(parent), m_status(Null) {}

void AbstractRestListModel::loadPage() {
  if (!m_networkManager->baseUrl().isValid()) {
    qmlWarning(this) << "BaseUrl not set";
    return;
  }

  QUrlQuery query = composeQuery();

  auto [future, reply] = m_networkManager->get(m_path, query);

  m_reply = reply;

  setStatus(Loading);
  future.then(this, [this](const QByteArray &data) {
    handleRequestData(data);
  }).onFailed(this, [this](const NetworkError &err) {
    m_errorString = err.message();
    setStatus(Error);
  });
}

NetworkManager *AbstractRestListModel::restManager() const {
  return m_networkManager;
}

void AbstractRestListModel::setRestManager(NetworkManager *newRestManager) {
  if (m_networkManager == newRestManager) {
    return;
  }

  m_networkManager = newRestManager;
  emit restManagerChanged();
}

RestPagination *AbstractRestListModel::pagination() const {
  return m_pagination;
}

void AbstractRestListModel::setPagination(RestPagination *newPagination) {
  if (m_pagination == newPagination) {
    return;
  }

  m_pagination = newPagination;
  emit paginationChanged();
}

QString AbstractRestListModel::orderBy() const {
  return m_orderBy;
}

void AbstractRestListModel::setOrderBy(const QString &newOrderBy) {
  if (m_orderBy == newOrderBy) {
    return;
  }

  m_orderBy = newOrderBy;
  emit orderByChanged();
}

QUrlQuery AbstractRestListModel::composeQuery() const {
  QUrlQuery query;

  for (const auto *filter : m_filters) {
    QString key = filter->key();
    QVariant value = filter->value();
    if (!value.isValid()) {
      if (!filter->excludeWhenEmpty()) {
        query.addQueryItem(key, "");
      }
      continue;
    }

    if (value.userType() == QMetaType::QVariantList) {
      QVariantList list = value.toList();
      if (list.isEmpty()) {
        if (!filter->excludeWhenEmpty()) {
          query.addQueryItem(key, "");
        }
        continue;
      }

      for (const auto &innerValue : list) {
        query.addQueryItem(key, innerValue.toString());
      }

    } else if (value.canConvert<QString>()) {
      auto valueString = value.toString();

      if (filter->excludeWhenEmpty() && valueString.isEmpty()) {
        continue;
      }

      query.addQueryItem(key, valueString);
    } else {
      qmlWarning(this) << "Could not convert value to query string:" << value;
    }
  }

  if (!m_orderBy.isNull()) {
    query.addQueryItem(m_orderByQuery, m_orderBy);
  }

  if (m_pagination) {
    for (const auto &[key, value] :
         m_pagination->queryParams().asKeyValueRange()) {
      query.addQueryItem(key, value);
    }
  }

  return query;
}

bool AbstractRestListModel::canFetchMore(const QModelIndex &parent) const {
  CHECK_CANFETCHMORE(parent);

  if (!m_pagination || !m_networkManager->baseUrl().isValid()) {
    return false;
  }

  if (m_reply) {
    return m_pagination->canFetchMore() && m_reply->isFinished();
  }

  return m_pagination->canFetchMore();
}

void AbstractRestListModel::fetchMore(const QModelIndex &parent) {
  CHECK_FETCHMORE(parent);

  if (!canFetchMore(parent)) {
    return;
  }

  fetchMoreHandler().call();
}

QJSValue AbstractRestListModel::fetchMoreHandler() const {
  if (!m_fetchMoreHandler.isCallable()) {
    QQmlEngine *engine = qmlEngine(this);
    if (engine) {
      m_fetchMoreHandler = engine->evaluate(QStringLiteral("(function() {})"));
    }
  }

  return m_fetchMoreHandler;
}

void AbstractRestListModel::setFetchMoreHandler(
  const QJSValue &newFetchMoreHandler) {
  if (!newFetchMoreHandler.isCallable()) {
    qmlInfo(this) << "fetchMoreHandler must be a callable function";
    return;
  }

  m_fetchMoreHandler = newFetchMoreHandler;
  emit fetchMoreHandlerChanged();
}

QJSValue AbstractRestListModel::preprocessItem() const {
  if (!m_preprocessItem.isCallable()) {
    QQmlEngine *engine = qmlEngine(this);
    if (engine) {
      m_preprocessItem =
        engine->evaluate(QStringLiteral("(function(obj) { return obj; })"));
    }
  }

  return m_preprocessItem;
}

void AbstractRestListModel::setPreprocessItem(
  const QJSValue &newPreprocessItem) {
  if (!newPreprocessItem.isCallable()) {
    qmlInfo(this) << "preprocessItem must be a callable function";
    return;
  }

  m_preprocessItem = newPreprocessItem;
  emit preprocessItemChanged();
}

AbstractRestListModel::Status AbstractRestListModel::status() const {
  return m_status;
}

void AbstractRestListModel::setStatus(Status newStatus) {
  if (m_status == newStatus) {
    return;
  }
  m_status = newStatus;
  emit statusChanged();
}

void AbstractRestListModel::resetRestModel() {
  m_reply = nullptr;
  setStatus(Null);
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

void AbstractRestListModel::reload() {
  reset();
  loadPage();
}

int AbstractRestListModel::count() const {
  return rowCount();
}

QString RestListModelFilter::key() const {
  return m_key;
}

void RestListModelFilter::setKey(const QString &newKey) {
  if (m_key == newKey) {
    return;
  }
  m_key = newKey;
  emit keyChanged();
}

QVariant RestListModelFilter::value() const {
  return m_value;
}

void RestListModelFilter::setValue(const QVariant &newValue) {
  if (m_value == newValue) {
    return;
  }
  m_value = newValue;
  emit valueChanged();
}

bool RestListModelFilter::excludeWhenEmpty() const {
  return m_excludeWhenEmpty;
}

void RestListModelFilter::setExcludeWhenEmpty(bool newExcludeWhenEmpty) {
  if (m_excludeWhenEmpty == newExcludeWhenEmpty) {
    return;
  }
  m_excludeWhenEmpty = newExcludeWhenEmpty;
  emit excludeWhenEmptyChanged();
}

QQmlListProperty<RestListModelFilter> AbstractRestListModel::filters() {
  QQmlListProperty<RestListModelFilter> list(this, &m_filters);
  list.append = &AbstractRestListModel::appendFilter;
  list.clear = &AbstractRestListModel::clearFilter;
  return list;
}

void AbstractRestListModel::appendFilter(RestListModelFilter *filter) {
  if (filter) {
    m_filters.append(filter);
  }
}

void AbstractRestListModel::clearFilter() {
  m_filters.clear();
}

void AbstractRestListModel::appendFilter(
  QQmlListProperty<RestListModelFilter> *propertyList,
  RestListModelFilter *filter) {
  auto *object = qobject_cast<AbstractRestListModel *>(propertyList->object);
  if (object) {
    object->appendFilter(filter);
  }
}

void AbstractRestListModel::clearFilter(
  QQmlListProperty<RestListModelFilter> *propertyList) {
  auto *object = qobject_cast<AbstractRestListModel *>(propertyList->object);
  if (object) {
    object->clearFilter();
  }
}
