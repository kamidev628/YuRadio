#include <QLoggingCategory>
Q_LOGGING_CATEGORY(itunesMusicInfoProviderLog,
                   "YuRadio.ItunesMusicInfoProviderBackend");

#include <QNetworkAccessManager>
#include <QNetworkReply>

#include "itunesmusicinfoproviderbackend.h"
#include "network/json.h"

using namespace Qt::StringLiterals;

ItunesMusicInfoProviderBackend::ItunesMusicInfoProviderBackend(QObject *parent)
    : MusicInfoProviderBackend(parent), m_apiManager(new NetworkManager(this)) {
  QUrl itunesUrl("https://itunes.apple.com");

  m_apiManager->setBaseUrl(itunesUrl);
}

void ItunesMusicInfoProviderBackend::provide(const QString &searchString) {
  m_searchTerm = searchString;

  QUrlQuery query;
  query.addQueryItem(QStringLiteral("term"), searchString);
  query.addQueryItem(QStringLiteral("media"), QStringLiteral("music"));

  auto [future, reply] = m_apiManager->get(QStringLiteral("/search"), query);

  future
    .then(this, [this, replyPtr = reply](const QByteArray &data) {
    handleReplyData(data);
  }).onFailed([this](const NetworkError & /*err*/) { emit errorOccurred(); });
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

void ItunesMusicInfoProviderBackend::handleReplyData(const QByteArray &data) {
  auto document = json::byteArrayToJson(data);
  if (!document) {
    emit errorOccurred();
    return;
  }

  Q_ASSERT(document->isObject());

  QJsonObject rootObject = document->object();
  QJsonArray results = rootObject[u"results"].toArray();

  if (results.isEmpty()) {
    qCInfo(itunesMusicInfoProviderLog)
      << "Itunes can't provide information about the song";
    emit errorOccurred();
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

  /* NOTE: I would like to use std::sort here but `QJsonValueRef` doesn't support `swap` operator */
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

  MusicInfoDetails info;

  info.albumName = bestMatch[u"collectionName"].toString();
  info.songName = bestMatch[u"trackName"].toString();
  info.artistNames.append(bestMatch[u"artistName"].toString());
  info.coverUrls.append(
    bestMatch[u"artworkUrl60"].toString().replace("60x60", "600x600"));
  QString releaseDateString = bestMatch[u"releaseDate"].toString();
  info.releaseDate =
    QDateTime::fromString(releaseDateString, Qt::ISODate).date();

  qCInfo(itunesMusicInfoProviderLog) << "Album Name" << info.albumName;
  qCInfo(itunesMusicInfoProviderLog) << "Song Name" << info.songName;
  qCInfo(itunesMusicInfoProviderLog) << "Artist Name" << info.artistNames[0];
  qCInfo(itunesMusicInfoProviderLog) << "albumImageUrl" << info.coverUrls[0];

  emit musicInformation(info);
}
