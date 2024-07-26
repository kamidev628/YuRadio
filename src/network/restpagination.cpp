#include "restpagination.h"

RestPagination::RestPagination(QObject *parent)
    : QObject(parent), m_totalCount(0) {}

int RestPagination::totalCount() const {
  return m_totalCount;
}

void RestPagination::setTotalCount(int totalCount) {
  if (m_totalCount == totalCount) {
    return;
  }

  m_totalCount = totalCount;
  emit totalCountChanged();
}
