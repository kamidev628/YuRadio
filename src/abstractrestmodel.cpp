#include <QJsonArray>

#include "abstractrestmodel.h"
#include "modelhelper.h"
#include "restpagination.h"

AbstractRestListModel::AbstractRestListModel(QObject *parent)
    : QAbstractListModel(parent), m_status(Null) {}

void AbstractRestListModel::loadPage() {
  if (m_networkManager->baseUrl().isEmpty()) {
    qWarning() << "BaseUrl not set";
    return;
  }

  QUrlQuery query = composeQuery();

  auto [future, reply] = m_networkManager->get(m_path, query);

  m_reply = reply;

  setStatus(Loading);
  future.then(this, [this](const QByteArray &data) {
    handleRequestData(data);
  }).onFailed(this, [this](const NetworkError &err) {
    setStatus(Error);
    m_errorString = err.message();
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

QVariantMap AbstractRestListModel::filters() const {
  return m_filters;
}

void AbstractRestListModel::setFilters(const QVariantMap &newFilters) {
  if (m_filters == newFilters) {
    return;
  }

  m_filters = newFilters;
  emit filtersChanged();
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

  for (const auto &[filter, value] : m_filters.asKeyValueRange()) {
    if (value.userType() == QMetaType::QVariantList) {
      for (const auto &innerValue : value.toList()) {
        query.addQueryItem(filter, innerValue.toString());
      }
    } else {
      query.addQueryItem(filter, value.toString());
    }
  }

  if (!m_orderBy.isNull()) {
    query.addQueryItem(m_orderByQuery, m_orderBy);
  }

  for (const auto &[key, value] :
       m_pagination->queryParams().asKeyValueRange()) {
    query.addQueryItem(key, value);
  }

  return query;
}

bool AbstractRestListModel::canFetchMore(const QModelIndex &parent) const {
  CHECK_CANFETCHMORE(parent);

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
      m_fetchMoreHandler = engine->evaluate(QStringLiteral("function() {}"));
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
        engine->evaluate(QStringLiteral("function(obj) { return obj; }"));
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
  setStatus(Null);
  m_reply = nullptr;
}
