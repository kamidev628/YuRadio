#include "musicinfomodel.h"
#include "itunesmusicinfoproviderbackend.h"

MusicInfo::MusicInfo(QObject *parent) : QObject(parent) {}

MusicInfo::MusicInfo(const MusicInfo &other)
    : QObject(nullptr), m_artistNames(other.m_artistNames),
      m_coverUrls(other.m_coverUrls), m_songName(other.m_songName),
      m_albumName(other.m_albumName), m_releaseDate(other.m_releaseDate) {}

MusicInfo::MusicInfo(const MusicInfoDetails &other)
    : QObject(nullptr), m_artistNames(other.artistNames),
      m_coverUrls(other.coverUrls), m_songName(other.songName),
      m_albumName(other.albumName), m_releaseDate(other.releaseDate) {}

QString MusicInfo::songName() const {
  return m_songName;
}

void MusicInfo::setSongName(const QString &newSongName) {
  m_songName = newSongName;
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
    : QObject(parent), m_musicInfo(new MusicInfo(this)), m_status(Null) {
  m_supportedBackends.append(new ItunesMusicInfoProviderBackend(this));

  registerBackend(0);
}

void MusicInfoModel::registerBackend(qsizetype index) {
  if (index >= 0 && index < m_supportedBackends.size() &&
      m_currentBackendIndex != index) {
    deregisterCurrentBackend();

    m_currentBackend = m_supportedBackends.at(index);
    m_currentBackendIndex = index;
    connect(m_currentBackend, &MusicInfoProviderBackend::musicInformation, this,
            &MusicInfoModel::handleMusicInformationDetails);
    connect(m_currentBackend, &MusicInfoProviderBackend::errorOccurred, this,
            &MusicInfoModel::switchToNextBackend);
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

  emit musicInfoChanged();
  setStatus(Ready);
}

bool MusicInfoModel::hasValidSearchTerm() const {
  return !m_searchTerm.isNull() && !m_searchTerm.isEmpty() &&
         m_searchTerm.size() >= 4;
}

void MusicInfoModel::refresh() {
  registerBackend(0);

  if (hasValidSearchTerm() && m_currentBackend) {
    requestMusicInfo();
  }
}

void MusicInfoModel::requestMusicInfo() {
  setStatus(Loading);
  m_currentBackend->provide(m_searchTerm);
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
