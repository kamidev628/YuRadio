#include <QJsonDocument>

#include "json.h"

std::optional<QJsonDocument> json::byteArrayToJson(const QByteArray &data) {
  QJsonParseError parseError;
  auto json = QJsonDocument::fromJson(data, &parseError);

  if (parseError.error) {
    qDebug() << "Data is not valid JSON:" << parseError.errorString() << "at"
             << parseError.offset << data;
    return {};
  }

  return json;
}
