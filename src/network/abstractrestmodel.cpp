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
    qmlWarning(this) << tr("BaseUrl is not set");
    return;
  }

  auto [future, reply] = m_networkManager->get(m_path, composeQuery());

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

bool AbstractRestListModel::tryAddFilter(QUrlQuery &query, const QString &key,
                                         const QVariant &value) const {
  if (!value.isValid()) {
    return false;
  }

  if (value.userType() == QMetaType::QVariantList) {
    QVariantList list = value.toList();
    if (list.isEmpty()) {
      return false;
    }

    qsizetype errorCount = 0;
    for (const auto &innerValue : list) {
      if (!innerValue.isValid()) {
        continue;
      }

      if (innerValue.canConvert<QString>()) {
        query.addQueryItem(key, innerValue.toString());
      } else {
        errorCount++;
        qmlWarning(this) << tr(
                              "Could not convert array element to string at %1")
                              .arg(list.indexOf(innerValue));
      }
    }
    if (errorCount == list.size()) {
      return false;
    }

  } else if (value.canConvert<QString>()) {
    QString valueString = value.toString();

    if (valueString.isEmpty()) {
      return false;
    }

    query.addQueryItem(key, value.toString());
  } else {
    qmlWarning(this) << tr("Could not convert value to query string:") << value;
  }

  return true;
};

QUrlQuery AbstractRestListModel::queryWithFilters() const {
  QUrlQuery query;

  for (const auto *filter : m_filters) {
    QString key = filter->key();
    QVariant value = filter->value();

    if (key.isEmpty()) {
      qmlWarning(this) << tr(
        "Filter with empty key is not allowed. Filter will be ignored");
      continue;
    }

    if (!tryAddFilter(query, key, value) && !filter->excludeWhenEmpty()) {
      query.addQueryItem(key, "");
    }
  }

  return query;
}

QUrlQuery AbstractRestListModel::composeQuery() const {
  QUrlQuery query = queryWithFilters();

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
    qmlInfo(this) << tr("fetchMoreHandler must be a callable function");
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
    qmlInfo(this) << tr("preprocessItem must be a callable function");
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

QString RestListModelSortFilter::key() const {
  return m_key;
}

void RestListModelSortFilter::setKey(const QString &newKey) {
  if (m_key == newKey) {
    return;
  }
  m_key = newKey;
  emit keyChanged();
}

QVariant RestListModelSortFilter::value() const {
  return m_value;
}

void RestListModelSortFilter::setValue(const QVariant &newValue) {
  if (m_value == newValue) {
    return;
  }
  m_value = newValue;
  emit valueChanged();
}

bool RestListModelSortFilter::excludeWhenEmpty() const {
  return m_excludeWhenEmpty;
}

void RestListModelSortFilter::setExcludeWhenEmpty(bool newExcludeWhenEmpty) {
  if (m_excludeWhenEmpty == newExcludeWhenEmpty) {
    return;
  }
  m_excludeWhenEmpty = newExcludeWhenEmpty;
  emit excludeWhenEmptyChanged();
}

QQmlListProperty<RestListModelSortFilter> AbstractRestListModel::filters() {
  QQmlListProperty<RestListModelSortFilter> list(this, &m_filters);
  list.append = &AbstractRestListModel::appendFilter;
  list.clear = &AbstractRestListModel::clearFilter;
  return list;
}

void AbstractRestListModel::appendFilter(RestListModelSortFilter *filter) {
  if (filter) {
    m_filters.append(filter);
  }
}

void AbstractRestListModel::clearFilter() {
  m_filters.clear();
}

void AbstractRestListModel::appendFilter(
  QQmlListProperty<RestListModelSortFilter> *propertyList,
  RestListModelSortFilter *filter) {
  auto *object = qobject_cast<AbstractRestListModel *>(propertyList->object);
  if (object) {
    object->appendFilter(filter);
  }
}

void AbstractRestListModel::clearFilter(
  QQmlListProperty<RestListModelSortFilter> *propertyList) {
  auto *object = qobject_cast<AbstractRestListModel *>(propertyList->object);
  if (object) {
    object->clearFilter();
  }
}
