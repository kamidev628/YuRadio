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

SpotifyBackend::SpotifyBackend(QObject *parent)
    : MusicInfoProviderBackend(parent) {
  auto *replyHandler = new QOAuthHttpServerReplyHandler(1337, this);
  replyHandler->setCallbackPath("/callback");

  m_oauth2.setReplyHandler(replyHandler);
  m_oauth2.setAuthorizationUrl(
    QUrl("https://accounts.spotify.com/authorize"_L1));
  m_oauth2.setAccessTokenUrl(QUrl("https://accounts.spotify.com/api/token"_L1));

  std::string clientId = SPOTIFY_CLIENTID;
  deobfuscate_str(clientId.data(), SPOTIFY_CLIENTID_HASH);

  std::string secret = SPOTIFY_SECRET;
  deobfuscate_str(secret.data(), SPOTIFY_SECRET_HASH);

  m_oauth2.setClientIdentifier(QString::fromStdString(clientId));
  m_oauth2.setClientIdentifierSharedKey(QString::fromStdString(secret));
  m_oauth2.setUserAgent(NetworkManager::applicationUserAgent());

  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::refreshTokenChanged, this,
          [](const QString &refreshToken) {
    QSettings settings;
    settings.setValue("SpotifyRefreshToken", refreshToken);
  });
  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::statusChanged, this,
          &SpotifyBackend::handleStatusChange);
  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::error, this,
          &SpotifyBackend::authenticationError);
  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::granted, this,
          &SpotifyBackend::authenticated);
  connect(&m_oauth2, &QOAuth2AuthorizationCodeFlow::authorizeWithBrowser, this,
          &QDesktopServices::openUrl);
}

void SpotifyBackend::grant() {
  QSettings settings;
  QVariant maybeRefreshToken = settings.value("SpotifyRefreshToken");

  if (maybeRefreshToken.isValid()) {
    m_oauth2.setRefreshToken(maybeRefreshToken.toString());
    m_oauth2.refreshAccessToken();
  } else {
    m_oauth2.grant();
  }
}

void SpotifyBackend::handleStatusChange(
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
  if (m_oauth2.status() != QAbstractOAuth::Status::Granted) {
    return;
  }

  QUrl searchUrl("https://api.spotify.com/v1/search"_L1);

  QUrlQuery query;
  query.addQueryItem(QStringLiteral("type"), QStringLiteral("track"));
  query.addQueryItem(QStringLiteral("q"), searchString);
  searchUrl.setQuery(query);

  QNetworkReply *reply = m_oauth2.get(searchUrl);

  connect(reply, &QNetworkReply::finished, this,
          [this, reply]() { handleMusicInfoReply(reply); });
}

void SpotifyBackend::handleMusicInfoReply(QNetworkReply *reply) {
  reply->deleteLater();
  if (reply->error()) {
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
  QJsonObject tracksObject = rootObject[u"tracks"].toObject();
  QJsonArray itemsArray = tracksObject[u"items"].toArray();
  if (!itemsArray.size()) {
    emit errorOccurred();
    return;
  }

  QJsonObject itemObject = itemsArray[0].toObject();
  QJsonObject albumObject = itemObject[u"album"].toObject();

  MusicInfoDetails info;

  for (auto artistObjectRef : itemObject[u"artists"].toArray()) {
    QJsonObject artistObject = artistObjectRef.toObject();
    info.artistNames.append(artistObject[u"name"].toString());
  }

  for (auto imageObjectRef : albumObject[u"images"].toArray()) {
    QJsonObject imageObject = imageObjectRef.toObject();
    info.coverUrls.append(imageObject[u"url"].toString());
  }

  info.songName = itemObject[u"name"].toString();
  info.albumName = albumObject[u"name"].toString();

  QString releaseDateString = albumObject[u"release_date"].toString();
  info.releaseDate =
    QDateTime::fromString(releaseDateString, Qt::ISODate).date();
  info.trackUrl = itemObject[u"external_urls"][u"spotify"].toString();

  qCInfo(spotifyBackendLog) << "Album Name" << info.albumName;
  qCInfo(spotifyBackendLog) << "Song Name" << info.songName;
  qCInfo(spotifyBackendLog) << "Artist Name" << info.artistNames[0];
  qCInfo(spotifyBackendLog) << "Image Url" << info.coverUrls[0];
  qCInfo(spotifyBackendLog) << "Track Url" << info.trackUrl;

  emit musicInformation(info);
}

bool SpotifyBackend::refreshAuthenticationSupported() {
  QSettings settings;
  return settings.contains("SpotifyRefreshToken");
}

QString SpotifyBackend::backendName() const {
  return "spotify";
}
