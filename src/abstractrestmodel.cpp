#include <QJsonArray>

#include "abstractrestmodel.h"
#include "restpagination.h"

void AbstractRestListModel::loadPage() {
  if (m_networkManager->baseUrl().isEmpty()) {
    qWarning() << "BaseUrl not set";
  }

  QUrlQuery query;

  queryApplyFilters(query);

  if (!m_orderBy.isNull()) {
    query.addQueryItem(m_orderByQuery, m_orderBy);
  }

  for (const auto &[key, value] :
       m_pagination->queryParams().asKeyValueRange()) {
    query.addQueryItem(key, value);
  }

  auto [future, reply] = m_networkManager->get(m_path, query);

  m_reply = reply;

  future
    .then(this, [this](const QByteArray &data) {
    handleRequestData(data);

    emit pageLoaded();
  }).onFailed(this, [this](const NetworkError &err) {
    qWarning() << err.message();
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

void AbstractRestListModel::clearReplies() {
  m_reply.reset();
}

void AbstractRestListModel::queryApplyFilters(QUrlQuery &query) {
  for (const auto &[filter, value] : m_filters.asKeyValueRange()) {
    if (value.userType() == QMetaType::QVariantList) {
      for (const auto &innerValue : value.toList()) {
        query.addQueryItem(filter, innerValue.toString());
      }
    } else {
      query.addQueryItem(filter, value.toString());
    }
  }
}
