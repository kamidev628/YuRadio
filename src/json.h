#include <QJsonDocument>

namespace json {

std::optional<QJsonDocument> byteArrayToJson(const QByteArray &data);

}  // namespace json
