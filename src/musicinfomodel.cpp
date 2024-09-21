#include <QLoggingCategory>
Q_LOGGING_CATEGORY(musicInfoModelLog, "YuRadio.MusicInfoModel");

#include "musicinfomodel.h"

#include "itunesbackend.h"
#include "spotifybackend.h"

MusicInfo::MusicInfo(QObject *parent) : QObject(parent) {}

QString MusicInfo::songName() const {
  return m_songName;
}

void MusicInfo::setSongName(const QString &newSongName) {
  m_songName = newSongName;
  emit dataChanged();
}

QUrl MusicInfo::trackUrl() const {
  return m_trackUrl;
}

void MusicInfo::setTrackUrl(const QUrl &newTrackUrl) {
  m_trackUrl = newTrackUrl;
  emit dataChanged();
}

QStringList MusicInfo::artistNames() const {
  return m_artistNames;
}

void MusicInfo::setArtistNames(const QStringList &newArtistNames) {
  m_artistNames = newArtistNames;
  emit dataChanged();
}

QList<QUrl> MusicInfo::coverUrls() const {
  return m_coverUrls;
}

void MusicInfo::setCoverUrls(const QList<QUrl> &newCoverUrls) {
  m_coverUrls = newCoverUrls;
  emit dataChanged();
}

QDate MusicInfo::releaseDate() const {
  return m_releaseDate;
}

void MusicInfo::setReleaseDate(const QDate &newReleaseDate) {
  m_releaseDate = newReleaseDate;
  emit dataChanged();
}

QString MusicInfo::albumName() const {
  return m_albumName;
}

void MusicInfo::setAlbumName(const QString &newAlbumName) {
  m_albumName = newAlbumName;
  emit dataChanged();
}

MusicInfoModel::MusicInfoModel(QObject *parent)
    : QObject(parent), m_spotify(new SpotifyBackend(this)),
      m_musicInfo(new MusicInfo(this)), m_status(Null) {
  connect(m_spotify, &SpotifyBackend::granted, this,
          &MusicInfoModel::spotifyAccessGranted);

  m_supportedBackends.append(new ItunesBackend(this));
  m_supportedBackends.append(m_spotify);

  registerBackend(0);
}

void MusicInfoModel::registerBackend(qsizetype index) {
  if (index >= 0 && index < m_supportedBackends.size()) {
    m_currentBackend = m_supportedBackends.at(index);
    m_currentBackendIndex = index;
    connect(m_currentBackend, &MusicInfoProviderBackend::musicInformation, this,
            &MusicInfoModel::handleMusicInformationDetails);
    connect(m_currentBackend, &MusicInfoProviderBackend::errorOccurred, this,
            &MusicInfoModel::switchToNextBackend);

    emit backendNameChanged();
  }
}

void MusicInfoModel::deregisterCurrentBackend() {
  if (m_currentBackend) {
    disconnect(m_currentBackend, &MusicInfoProviderBackend::musicInformation,
               this, &MusicInfoModel::handleMusicInformationDetails);
    disconnect(m_currentBackend, &MusicInfoProviderBackend::errorOccurred, this,
               &MusicInfoModel::switchToNextBackend);
    m_currentBackend = nullptr;
  }
}

void MusicInfoModel::switchToNextBackend() {
  deregisterCurrentBackend();
  registerBackend(m_currentBackendIndex + 1);
  if (m_currentBackend) {
    requestMusicInfo();
  } else {
    setStatus(Error);
  }
}

QString MusicInfoModel::searchTerm() const {
  return m_searchTerm;
}

void MusicInfoModel::setSearchTerm(const QString &newSearchTerm) {
  if (m_searchTerm != newSearchTerm) {
    m_searchTerm = newSearchTerm;
    emit searchTermChanged();
  }
}

void MusicInfoModel::handleMusicInformationDetails(
  const MusicInfoDetails &details) {
  m_musicInfo->setArtistNames(details.artistNames);
  m_musicInfo->setCoverUrls(details.coverUrls);
  m_musicInfo->setSongName(details.songName);
  m_musicInfo->setAlbumName(details.albumName);
  m_musicInfo->setReleaseDate(details.releaseDate);
  m_musicInfo->setTrackUrl(details.trackUrl);

  emit musicInfoChanged();
  setStatus(Ready);
}

bool MusicInfoModel::hasValidSearchTerm() const {
  return !m_searchTerm.isNull() && !m_searchTerm.isEmpty() &&
         m_searchTerm.trimmed().size() >= 4;
}

void MusicInfoModel::refresh() {
  deregisterCurrentBackend();
  registerBackend(0);

  if (hasValidSearchTerm() && m_currentBackend) {
    requestMusicInfo();
  }
}

void MusicInfoModel::requestMusicInfo() {
  setStatus(Loading);
  m_currentBackend->requestMusicInfo(m_searchTerm);
}

QString MusicInfoModel::backendName() const {
  return m_currentBackend ? m_currentBackend->backendName() : QString();
}

void MusicInfoModel::grantSpotifyAccess() {
  m_spotify->grant();
}

MusicInfo *MusicInfoModel::musicInfo() const {
  return m_musicInfo;
}

MusicInfoModel::Status MusicInfoModel::status() const {
  return m_status;
}

void MusicInfoModel::setStatus(Status status) {
  if (m_status != status) {
    m_status = status;
    emit statusChanged();
  }
}
