#ifndef SPOTIFYBACKEND_H
#define SPOTIFYBACKEND_H

#include <QObject>

#include <QOAuth2AuthorizationCodeFlow>

#include "musicinfoproviderbackend.h"

class SpotifyBackend : public MusicInfoProviderBackend {
  Q_OBJECT

public:
  explicit SpotifyBackend(QObject *parent = nullptr);

  void requestMusicInfo(const QString &searchString) override;
  QString backendName() const override;

public slots:
  void grant();

signals:
  void granted();
  void authorizationError(const QString &error, const QString &errorDescription,
                          const QUrl &uri);

private slots:
  void statusChanged(QOAuth2AuthorizationCodeFlow::Status status);
  void requestFailed(QAbstractOAuth::Error error);
  void processMusciInfoReply(QNetworkReply *reply);

  void updateRefreshTimer(const QDateTime &expiration);
  bool accessGranted();
  void tryAuthorize();

private:
  struct AccessTokenData {
    QString accessToken;
    QDateTime expiration;

    bool isValid() const {
      return !accessToken.isNull() && expiration.isValid() &&
             QDateTime::currentDateTime() < expiration;
    }
  };

  static QString storedRefreshToken();
  static AccessTokenData storedAccessToken();
  static void setStoredRefreshToken(const QString &refreshToken);
  static void setStoredAccessToken(const QString &accessToken);
  static void setStoredAccessTokenExpiration(const QDateTime &date);

private:
  QOAuth2AuthorizationCodeFlow m_oauth2;
  QTimer m_refreshTokenTimer;
};

#endif /* !SPOTIFYBACKEND_H */
