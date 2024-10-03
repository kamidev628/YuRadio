#ifndef SQLQUERYMODEL_H
#define SQLQUERYMODEL_H

#include <QSqlQueryModel>
#include <QtQmlIntegration>

class SqlQueryModel : public QSqlQueryModel {
  Q_OBJECT
  Q_PROPERTY(QString queryString READ queryString WRITE setQueryString NOTIFY
               queryStringChanged FINAL)
  QML_ELEMENT

public:
  explicit SqlQueryModel(QObject *parent = nullptr);

  Q_INVOKABLE void refresh();

  QString queryString() const;
  void setQueryString(const QString &newQueryString);

signals:
  void queryStringChanged();

private:
  QString m_queryString;
};

#endif /* !SQLQUERYMODEL_H */
