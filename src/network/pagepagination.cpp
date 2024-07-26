#include "pagepagination.h"

PagePagination::PagePagination(QObject *parent) : RestPagination(parent) {}

int PagePagination::perPage() const {
  return m_perPage;
}

void PagePagination::setPerPage(int perPage) {
  if (m_perPage == perPage) {
    return;
  }

  m_perPage = perPage;
  emit perPageChanged();
}

int PagePagination::currentPage() const {
  return m_currentPage;
}

void PagePagination::setCurrentPage(int currentPage) {
  if (m_currentPage == currentPage) {
    return;
  }

  m_currentPage = currentPage;
  emit currentPageChanged();
}

QHash<QString, QString> PagePagination::queryParams() const {
  QHash<QString, QString> params;
  params[m_currentPageQuery] = QString::number(m_currentPage);
  params[m_perPageQuery] = QString::number(m_perPage);
  return params;
}

QString PagePagination::perPageQuery() const {
  return m_perPageQuery;
}

void PagePagination::setPerPageQuery(const QString &newPerPageQuery) {
  if (m_perPageQuery == newPerPageQuery) {
    return;
  }

  m_perPageQuery = newPerPageQuery;
  emit perPageQueryChanged();
}

QString PagePagination::currentPageQuery() const {
  return m_currentPageQuery;
}

void PagePagination::setCurrentPageQuery(const QString &newCurrentPageQuery) {
  if (m_currentPageQuery == newCurrentPageQuery) {
    return;
  }

  m_currentPageQuery = newCurrentPageQuery;
  emit currentPageQueryChanged();
}

void PagePagination::nextPage() {
  setCurrentPage(m_currentPage + 1);
}

void PagePagination::prevPage() {
  setCurrentPage(m_currentPage - 1);
}

bool PagePagination::canFetchMore() {
  return m_perPage * m_currentPage < m_totalCount;
}
