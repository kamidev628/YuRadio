#include <QSqlQuery>

#include "sqlquerymodel.h"

using namespace Qt::StringLiterals;

SqlQueryModel::SqlQueryModel(QObject *parent) : QSqlQueryModel(parent) {}

void SqlQueryModel::refresh() {
  setQuery(m_queryString);
}

QString SqlQueryModel::queryString() const {
  return m_queryString;
}

void SqlQueryModel::setQueryString(const QString &newQueryString) {
  if (m_queryString != newQueryString) {
    m_queryString = newQueryString;

    emit queryStringChanged();
  }
}
