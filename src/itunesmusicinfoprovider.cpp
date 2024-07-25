#include <QLoggingCategory>
Q_LOGGING_CATEGORY(itunesMusicInfoProviderLog,
                   "YuRadio.ItunesMusicInfoProvider");

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
  m_searchTerm = searchString;

  QUrlQuery query;
  query.addQueryItem(QStringLiteral("term"), searchString);
  query.addQueryItem(QStringLiteral("media"), QStringLiteral("music"));

  auto [future, reply] = m_apiManager->get(QStringLiteral("/search"), query);

  setState(Processing);
  future.then(this, [this](const QByteArray &data) {
    handleReplyData(data);
  }).onFailed([this](const NetworkError & /*err*/) { setState(Failed); });
}

qsizetype levenshteinDistance(const QString &source, const QString &target) {
  if (source == target) {
    return 0;
  }

  const qsizetype sourceCount = source.size();
  const qsizetype targetCount = target.size();

  if (source.isEmpty()) {
    return targetCount;
  }

  if (target.isEmpty()) {
    return sourceCount;
  }

  if (sourceCount > targetCount) {
    return levenshteinDistance(target, source);
  }

  QList<int> column;
  column.fill(0, targetCount + 1);
  QList<int> previousColumn;
  previousColumn.reserve(targetCount + 1);
  for (int i = 0; i < targetCount + 1; i++) {
    previousColumn.append(i);
  }

  for (int i = 0; i < sourceCount; i++) {
    column[0] = i + 1;
    for (int j = 0; j < targetCount; j++) {
      column[j + 1] =
        std::min({1 + column.at(j), 1 + previousColumn.at(1 + j),
                  previousColumn.at(j) + (source.at(i) != target.at(j))});
    }
    column.swap(previousColumn);
  }

  return previousColumn.at(targetCount);
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
    qInfo(itunesMusicInfoProviderLog)
      << "Itunes can't provide information about the song";
    setState(Failed);
    return;
  }

  struct SortParameters {
    qsizetype distance;
    QDateTime releaseDate;

    bool operator==(const SortParameters &rhs) const {
      return distance == rhs.distance && releaseDate == rhs.releaseDate;
    }

    bool operator<(const SortParameters &rhs) const {
      return std::tie(distance, releaseDate) <
             std::tie(rhs.distance, rhs.releaseDate);
    }
  };

  QMap<SortParameters, qsizetype> similarityMap;

  for (qsizetype i = 0; i < results.count(); ++i) {
    QJsonObject musicInfo = results[i].toObject();

    QString artistName = musicInfo[u"artistName"].toString();
    QString songName = musicInfo[u"trackName"].toString();

    QString fullSongName = artistName + songName;

    QString releaseDateString = musicInfo[u"releaseDate"].toString();
    QDateTime releaseDate =
      QDateTime::fromString(releaseDateString, Qt::ISODate);

    SortParameters params{levenshteinDistance(fullSongName, m_searchTerm),
                          releaseDate};
    similarityMap[params] = i;
  }

  QJsonObject bestMatch = results[similarityMap.first()].toObject();

  QString albumName = bestMatch[u"collectionName"].toString();
  QString songName = bestMatch[u"trackName"].toString();
  QString artistName = bestMatch[u"artistName"].toString();
  QUrl albumImageUrl =
    bestMatch[u"artworkUrl60"].toString().replace("60x60", "600x600");
  QString releaseDateString = bestMatch[u"releaseDate"].toString();
  QDateTime releaseDate = QDateTime::fromString(releaseDateString, Qt::ISODate);

  qCInfo(itunesMusicInfoProviderLog) << "Album Name" << albumName;
  qCInfo(itunesMusicInfoProviderLog) << "Song Name" << songName;
  qCInfo(itunesMusicInfoProviderLog) << "Artist Name" << artistName;
  qCInfo(itunesMusicInfoProviderLog) << "albumImageUrl" << albumImageUrl;

  auto *musicInfo = new MusicInfo;
  auto *album = new MusicAlbum(musicInfo);
  album->setAlbumName(albumName);
  album->setAlbumImageUrl(albumImageUrl);
  album->setReleaseDate(releaseDate.date());

  auto *musicArtist = new MusicArtist(album);
  musicArtist->setArtistName(artistName);
  album->addArtist(musicArtist);

  musicInfo->setAlbum(album);
  musicInfo->setSongName(songName);

  setMusicInfo(musicInfo);
  setState(Done);
}
