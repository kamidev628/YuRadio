#include <QLoggingCategory>
Q_LOGGING_CATEGORY(itunesBackendLog, "YuRadio.ItunesBackend");

#include <QNetworkAccessManager>
#include <QNetworkReply>

#include "algorithm.h"
#include "itunesbackend.h"
#include "network/json.h"

using namespace Qt::StringLiterals;

ItunesBackend::ItunesBackend(QObject *parent)
    : MusicInfoProviderBackend(parent),
      m_networkManager(new NetworkManager(this)) {
  QUrl itunesUrl("https://itunes.apple.com");

  m_networkManager->setBaseUrl(itunesUrl);
}

void ItunesBackend::requestMusicInfo(const QString &searchString) {
  m_response.cancel();
  m_searchTerm = searchString;

  QUrlQuery query;
  query.addQueryItem(QStringLiteral("term"), searchString);
  query.addQueryItem(QStringLiteral("media"), QStringLiteral("music"));

  m_response = m_networkManager->get(QStringLiteral("/search"), query);

  m_response
    .then(this, [this](const QByteArray &data) {
    handleReplyData(data);
  }).onFailed([this](const NetworkError & /*err*/) { emit errorOccurred(); });
}

void ItunesBackend::handleReplyData(const QByteArray &data) {
  auto document = json::byteArrayToJson(data);
  if (!document) {
    emit errorOccurred();
    return;
  }

  Q_ASSERT(document->isObject());

  QJsonObject rootObject = document->object();
  QJsonArray results = rootObject[u"results"].toArray();

  if (results.isEmpty()) {
    qCInfo(itunesBackendLog)
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

    qsizetype levenshteinDistance =
      algorithm::levenshteinDistance(fullSongName, m_searchTerm);
    similarityMap.insert({levenshteinDistance, releaseDate}, i);
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
  info.trackUrl = bestMatch[u"trackViewUrl"].toString();

  qCInfo(itunesBackendLog) << "Album Name" << info.albumName;
  qCInfo(itunesBackendLog) << "Song Name" << info.songName;
  qCInfo(itunesBackendLog) << "Artist Name" << info.artistNames[0];
  qCInfo(itunesBackendLog) << "Image Url" << info.coverUrls[0];
  qCInfo(itunesBackendLog) << "Track Url" << info.trackUrl;

  emit musicInformation(info);
}

QString ItunesBackend::backendName() const {
  return "itunes";
}
