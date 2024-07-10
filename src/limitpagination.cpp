#include "limitpagination.h"

LimitPagination::LimitPagination(QObject *parent)
    : RestPagination(parent), m_limit(20), m_offset(0), m_limitQuery("limit"),
      m_offsetQuery("offset") {}

QString LimitPagination::limitQuery() const {
  return m_limitQuery;
}

void LimitPagination::setLimitQuery(const QString &newLimitQuery) {
  if (m_limitQuery == newLimitQuery) {
    return;
  }

  m_limitQuery = newLimitQuery;
  emit limitQueryChanged();
}

QString LimitPagination::offsetQuery() const {
  return m_offsetQuery;
}

void LimitPagination::setOffsetQuery(const QString &newOffsetQuery) {
  if (m_offsetQuery == newOffsetQuery) {
    return;
  }

  m_offsetQuery = newOffsetQuery;
  emit offsetQueryChanged();
}

int LimitPagination::limit() const {
  return m_limit;
}

void LimitPagination::setLimit(int newLimit) {
  if (m_limit == newLimit) {
    return;
  }

  m_limit = newLimit;
  emit limitChanged();
}

int LimitPagination::offset() const {
  return m_offset;
}

void LimitPagination::setOffset(int newOffset) {
  if (m_offset == newOffset) {
    return;
  }

  m_offset = newOffset;
  emit offsetChanged();
}

QHash<QString, QString> LimitPagination::queryParams() const {
  QHash<QString, QString> params;
  params[m_limitQuery] = QString::number(m_limit);
  params[m_offsetQuery] = QString::number(m_offset);
  return params;
}

void LimitPagination::nextPage() {
  setOffset(m_offset + m_limit);
}

void LimitPagination::prevPage() {
  setOffset(m_offset - m_limit);
}

bool LimitPagination::hasNextPage() {
  return m_offset + m_limit <= m_totalCount;
}

bool LimitPagination::canFetchMore() {
  return m_offset < m_totalCount;
}
