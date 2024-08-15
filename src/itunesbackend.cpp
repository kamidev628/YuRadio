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
  QUrl itunesUrl(u"https://itunes.apple.com"_s);

  m_networkManager->setBaseUrl(itunesUrl);
}

void ItunesBackend::requestMusicInfo(const QString &searchString) {
  m_response.cancel();
  m_searchTerm = searchString;

  QUrlQuery query;
  query.addQueryItem(u"term"_s, searchString);
  query.addQueryItem(u"media"_s, u"music"_s);

  m_response = m_networkManager->get(u"/search"_s, query);

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
  QJsonArray results = rootObject["results"_L1].toArray();

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

    QString artistName = musicInfo["artistName"_L1].toString();
    QString songName = musicInfo["trackName"_L1].toString();

    QString fullSongName = artistName + songName;

    QString releaseDateString = musicInfo["releaseDate"_L1].toString();
    QDateTime releaseDate =
      QDateTime::fromString(releaseDateString, Qt::ISODate);

    qsizetype levenshteinDistance =
      algorithm::levenshteinDistance(fullSongName, m_searchTerm);
    similarityMap.insert({levenshteinDistance, releaseDate}, i);
  }

  QJsonObject bestMatch = results[similarityMap.first()].toObject();

  MusicInfoDetails info;

  info.albumName = bestMatch["collectionName"_L1].toString();
  info.songName = bestMatch["trackName"_L1].toString();
  info.artistNames.append(bestMatch["artistName"_L1].toString());
  info.coverUrls.append(
    bestMatch["artworkUrl60"_L1].toString().replace("60x60"_L1, "600x600"_L1));
  QString releaseDateString = bestMatch["releaseDate"_L1].toString();
  info.releaseDate =
    QDateTime::fromString(releaseDateString, Qt::ISODate).date();
  info.trackUrl = bestMatch["trackViewUrl"_L1].toString();

  qCInfo(itunesBackendLog) << "Album Name" << info.albumName;
  qCInfo(itunesBackendLog) << "Song Name" << info.songName;
  qCInfo(itunesBackendLog) << "Artist Name" << info.artistNames[0];
  qCInfo(itunesBackendLog) << "Image Url" << info.coverUrls[0];
  qCInfo(itunesBackendLog) << "Track Url" << info.trackUrl;

  emit musicInformation(info);
}

QString ItunesBackend::backendName() const {
  return u"itunes"_s;
}
