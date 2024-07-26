#ifndef NETWORKERROR_H
#define NETWORKERROR_H

#include <QNetworkReply>

using NetworkErrorType = QNetworkReply::NetworkError;

class NetworkError {
public:
  NetworkError(NetworkErrorType type, QString message)
      : m_type(type), m_message(std::move(message)) {}

  NetworkErrorType type() const { return m_type; }

  operator bool() const { return m_type != QNetworkReply::NoError; }

  QString message() const { return m_message; }

private:
  NetworkErrorType m_type;
  QString m_message;
};

#endif /* !NETWORKERROR_H */
