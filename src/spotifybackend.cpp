#include <QLoggingCategory>
Q_LOGGING_CATEGORY(spotifyBackendLog, "YuRadio.SpotifyBackend");

#include <QDesktopServices>
#include <QOAuthHttpServerReplyHandler>

#include <QNetworkReply>
#include <QSettings>
#include <QUrlQuery>

#include "applicationconfig.h"
#include "network/json.h"
#include "network/networkmanager.h"
#include "obf.h"
#include "spotifybackend.h"

using namespace Qt::StringLiterals;
using namespace std::chrono_literals;

SpotifyBackend::SpotifyBackend(QObject *parent)
    : MusicInfoProviderBackend(parent) {
  auto *replyHandler = new QOAuthHttpServerReplyHandler(1337, this);
  replyHandler->setCallbackPath(u"/callback"_s);

  m_oauth2.setReplyHandler(replyHandler);
  m_oauth2.setAuthorizationUrl(
    QUrl(u"https://accounts.spotify.com/authorize"_s));
  m_oauth2.setAccessTokenUrl(QUrl(u"https://accounts.spotify.com/api/token"_s));

  std::string clientId = SPOTIFY_CLIENTID;
  deobfuscate_str(clientId.data(), SPOTIFY_CLIENTID_HASH);

  std::string secret = SPOTIFY_SECRET;
  deobfuscate_str(secret.data(), SPOTIFY_SECRET_HASH);

  m_oauth2.setClientIdentifier(QString::fromStdString(clientId));
  m_oauth2.setClientIdentifierSharedKey(QString::fromStdString(secret));
  m_oauth2.setUserAgent(NetworkManager::applicationUserAgent());
  m_oauth2.setNetworkAccessManager(new NetworkManager(this));

  m_refreshTokenTimer.setSingleShot(true);

  QMetaObject::invokeMethod(this, &SpotifyBackend::tryAuthorize,
                            Qt::QueuedConnection);

  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::tokenChanged, this,
          &SpotifyBackend::setStoredAccessToken);
  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::expirationAtChanged, this,
          &SpotifyBackend::setStoredAccessTokenExpiration);
  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::refreshTokenChanged, this,
          &SpotifyBackend::setStoredRefreshToken);
  connect(
    &m_oauth2, &QOAuth2AuthorizationCodeFlow::error, this,
    [](const QString &error, const QString &errorDescription, const QUrl &uri) {
    qCDebug(spotifyBackendLog) << "Error:" << error << errorDescription << uri;
  });
  connect(&m_oauth2,
          &QOAuth2AuthorizationCodeFlow::authorizationCallbackReceived, this,
          [](const QVariantMap & /*data*/) {
    qCDebug(spotifyBackendLog) << "Authorization Callback Received";
  });
  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::expirationAtChanged, this,
          &SpotifyBackend::updateRefreshTimer);
  connect(&m_refreshTokenTimer, &QTimer::timeout, &m_oauth2,
          &QOAuth2AuthorizationCodeFlow::refreshAccessToken);
  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::statusChanged, this,
          &SpotifyBackend::statusChanged);
  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::error, this,
          &SpotifyBackend::authorizationError);
  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::granted, this,
          &SpotifyBackend::granted);
  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::requestFailed, this,
          &SpotifyBackend::requestFailed);
  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::authorizeWithBrowser, this,
          &QDesktopServices::openUrl);
}

void SpotifyBackend::grant() {
  if (!accessGranted()) {
    m_oauth2.grant();
  }
}

void SpotifyBackend::statusChanged(
  QOAuth2AuthorizationCodeFlow::Status status) {
  switch (status) {
    case QAbstractOAuth::Status::NotAuthenticated:
      qCDebug(spotifyBackendLog) << "NotAuthenticated";
      break;
    case QAbstractOAuth::Status::TemporaryCredentialsReceived:
      qCDebug(spotifyBackendLog) << "TemporaryCredentialsReceived";
      break;
    case QAbstractOAuth::Status::Granted:
      qCDebug(spotifyBackendLog) << "Granted";
      break;
    case QAbstractOAuth::Status::RefreshingToken:
      qCDebug(spotifyBackendLog) << "RefreshingToken";
      break;
  }
}

void SpotifyBackend::requestMusicInfo(const QString &searchString) {
  if (!accessGranted()) {
    qCDebug(spotifyBackendLog) << "Access is not granted";
    emit errorOccurred();
    return;
  }

  QUrl searchUrl(u"https://api.spotify.com/v1/search"_s);

  QUrlQuery query;
  query.addQueryItem(u"type"_s, u"track"_s);
  query.addQueryItem(u"limit"_s, u"1"_s);
  query.addQueryItem(u"q"_s, searchString);
  searchUrl.setQuery(query);

  QNetworkReply *reply = m_oauth2.get(searchUrl);

  connect(reply, &QNetworkReply::finished, this,
          [this, reply]() { processMusciInfoReply(reply); });
  connect(reply, &QNetworkReply::finished, reply, &QObject::deleteLater);
}

void SpotifyBackend::processMusciInfoReply(QNetworkReply *reply) {
  if (reply->error()) {
    qCWarning(spotifyBackendLog) << reply->errorString() << reply->readAll();
    tryAuthorize();
    emit errorOccurred();
    return;
  }

  QByteArray data = reply->readAll();
  auto document = json::byteArrayToJson(data);
  if (!document) {
    emit errorOccurred();
    return;
  }

  QJsonObject rootObject = document->object();
  QJsonObject tracksObject = rootObject["tracks"_L1].toObject();
  QJsonArray itemsArray = tracksObject["items"_L1].toArray();
  if (itemsArray.isEmpty()) {
    emit errorOccurred();
    return;
  }

  QJsonObject itemObject = itemsArray[0].toObject();
  QJsonObject albumObject = itemObject["album"_L1].toObject();

  MusicInfoDetails info;

  for (auto artistObjectRef : itemObject["artists"_L1].toArray()) {
    QJsonObject artistObject = artistObjectRef.toObject();
    info.artistNames.append(artistObject["name"_L1].toString());
  }

  for (auto imageObjectRef : albumObject["images"_L1].toArray()) {
    QJsonObject imageObject = imageObjectRef.toObject();
    info.coverUrls.append(imageObject["url"_L1].toString());
  }

  info.songName = itemObject["name"_L1].toString();
  info.albumName = albumObject["name"_L1].toString();

  QString releaseDateString = albumObject["release_date"_L1].toString();
  info.releaseDate =
    QDateTime::fromString(releaseDateString, Qt::ISODate).date();
  info.trackUrl = itemObject["external_urls"_L1]["spotify"_L1].toString();

  qCInfo(spotifyBackendLog) << "Album Name" << info.albumName;
  qCInfo(spotifyBackendLog) << "Song Name" << info.songName;
  qCInfo(spotifyBackendLog) << "Artist Name" << info.artistNames[0];
  qCInfo(spotifyBackendLog) << "Image Url" << info.coverUrls[0];
  qCInfo(spotifyBackendLog) << "Track Url" << info.trackUrl;

  emit musicInformation(info);
}

QString SpotifyBackend::backendName() const {
  return u"spotify"_s;
}

QString SpotifyBackend::storedRefreshToken() {
  QSettings settings;
  return settings.value("SpotifyRefreshToken"_L1).toString();
}

void SpotifyBackend::setStoredRefreshToken(const QString &refreshToken) {
  QSettings settings;
  settings.setValue("SpotifyRefreshToken"_L1, refreshToken);
}

SpotifyBackend::AccessTokenData SpotifyBackend::storedAccessToken() {
  QSettings settings;
  QString accessToken = settings.value("SpotifyAccessToken"_L1).toString();
  QDateTime expirationDate =
    settings.value("SpotifyAccessTokenExpiration"_L1).toDateTime();
  return {accessToken, expirationDate};
}

void SpotifyBackend::setStoredAccessToken(const QString &accessToken) {
  QSettings settings;
  settings.setValue("SpotifyAccessToken"_L1, accessToken);
}

void SpotifyBackend::setStoredAccessTokenExpiration(const QDateTime &date) {
  QSettings settings;
  settings.setValue("SpotifyAccessTokenExpiration"_L1, date);
}

void SpotifyBackend::updateRefreshTimer(const QDateTime &expiration) {
  qCDebug(spotifyBackendLog) << "Token Expiration:" << expiration;

  QDateTime currentDate = QDateTime::currentDateTime();
  auto refreshInterval =
    std::chrono::milliseconds(currentDate.msecsTo(expiration)) - 1min;

  if (refreshInterval < 1min) {
    m_refreshTokenTimer.setInterval(0);
  } else {
    m_refreshTokenTimer.setInterval(refreshInterval);
  }

  m_refreshTokenTimer.start();
}

bool SpotifyBackend::accessGranted() {
  AccessTokenData accessTokenData = storedAccessToken();

  return m_oauth2.status() == QAbstractOAuth::Status::Granted ||
         accessTokenData.isValid();
}

void SpotifyBackend::tryAuthorize() {
  AccessTokenData accessTokenData = storedAccessToken();
  if (accessTokenData.isValid()) {
    m_oauth2.setToken(accessTokenData.accessToken);
    updateRefreshTimer(accessTokenData.expiration);
  }

  QString refreshToken = storedRefreshToken();
  if (!refreshToken.isNull()) {
    m_oauth2.setRefreshToken(refreshToken);

    if (!accessTokenData.isValid()) {
      m_oauth2.refreshAccessToken();
    }
  }
}

void SpotifyBackend::requestFailed(QAbstractOAuth::Error error) {
  switch (error) {
    case QAbstractOAuth::Error::NoError:
      qCDebug(spotifyBackendLog) << "NoError";
      break;
    case QAbstractOAuth::Error::NetworkError:
      qCDebug(spotifyBackendLog) << "NetworkError";
      break;
    case QAbstractOAuth::Error::ServerError:
      qCDebug(spotifyBackendLog) << "ServerError";
      break;
    case QAbstractOAuth::Error::OAuthTokenNotFoundError:
      qCDebug(spotifyBackendLog) << "OAuthTokenNotFoundError";
      break;
    case QAbstractOAuth::Error::OAuthTokenSecretNotFoundError:
      qCDebug(spotifyBackendLog) << "OAuthTokenSecretNotFoundError";
      break;
    case QAbstractOAuth::Error::OAuthCallbackNotVerified:
      qCDebug(spotifyBackendLog) << "OAuthCallbackNotVerified";
      break;
  }
}
