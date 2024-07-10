#include <QNetworkAccessManager>
#include <QNetworkReply>

#include "itunesmusicinfoprovider.h"
#include "json.h"

using namespace Qt::StringLiterals;

ItunesMusicInfoProvider::ItunesMusicInfoProvider(QObject *parent)
    : MusicInfoProvider(parent), m_apiManager(new NetworkManager(this)) {
  QUrl itunesUrl("https://itunes.apple.com");

  m_apiManager->setBaseUrl(itunesUrl);
}

void ItunesMusicInfoProvider::provide(const QString &searchString) {
  QUrlQuery query;
  query.addQueryItem(QStringLiteral("term"), searchString);
  query.addQueryItem(QStringLiteral("media"), QStringLiteral("music"));

  auto [future, reply] = m_apiManager->get(QStringLiteral("/search"), query);

  setState(Processing);
  future.then(this, [this](const QByteArray &data) {
    handleReplyData(data);
  }).onFailed([this](const NetworkError & /*err*/) { setState(Failed); });
}

void ItunesMusicInfoProvider::handleReplyData(const QByteArray &data) {
  auto document = json::byteArrayToJson(data);
  if (!document) {
    setState(Failed);
    return;
  }

  Q_ASSERT(document->isObject());

  QJsonObject rootObject = document->object();
  QJsonArray results = rootObject[u"results"].toArray();

  if (results.isEmpty()) {
    qDebug() << "Itunes can't provide information about the song";
    setState(Failed);
    return;
  }

  QDateTime firstReleaseDate;
  QJsonObject earlisetRelease;

  for (const auto &result : results) {
    QJsonObject musicInfo = result.toObject();

    QString releaseDateString = musicInfo[u"releaseDate"].toString();
    QDateTime releaseDate =
      QDateTime::fromString(releaseDateString, Qt::ISODate);

    if (firstReleaseDate.isNull() || firstReleaseDate > releaseDate) {
      firstReleaseDate = releaseDate;
      earlisetRelease = std::move(musicInfo);
    }
  }

  QString albumName = earlisetRelease[u"collectionName"].toString();
  QString songName = earlisetRelease[u"trackName"].toString();
  QString artistName = earlisetRelease[u"artistName"].toString();
  QUrl albumImageUrl =
    earlisetRelease[u"artworkUrl60"].toString().replace("60x60", "600x600");

  qDebug() << "Album Name" << albumName;
  qDebug() << "Song Name" << songName;
  qDebug() << "Artist Name" << artistName;
  qDebug() << "albumImageUrl" << albumImageUrl;

  auto *musicInfo = new MusicInfo;
  auto *album = new MusicAlbum(musicInfo);
  album->setAlbumName(albumName);
  album->setAlbumImageUrl(albumImageUrl);
  album->setReleaseDate(firstReleaseDate.date());

  auto *musicArtist = new MusicArtist(album);
  musicArtist->setArtistName(artistName);
  album->addArtist(musicArtist);

  musicInfo->setAlbum(album);
  musicInfo->setSongName(songName);

  setMusicInfo(musicInfo);
  setState(Done);
}
