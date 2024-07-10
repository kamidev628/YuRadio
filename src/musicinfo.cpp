#include <QPointer>

#include "musicinfo.h"

MusicInfo::MusicInfo(QObject *parent) : QObject(parent) {}

MusicAlbum::MusicAlbum(QObject *parent) : QObject(parent) {}

MusicArtist::MusicArtist(QObject *parent) : QObject(parent) {}

void MusicAlbum::addArtist(MusicArtist *artist) {
  m_artists.push_back(artist);
}

QUrl MusicAlbum::albumImageUrl() const {
  return m_albumImageUrl;
}

void MusicAlbum::setAlbumImageUrl(const QUrl &newAlbumImageUrl) {
  if (m_albumImageUrl == newAlbumImageUrl) {
    return;
  }
  m_albumImageUrl = newAlbumImageUrl;
  emit albumImageUrlChanged();
}

QList<MusicArtist *> MusicAlbum::artists() const {
  return m_artists;
}

void MusicAlbum::setArtists(const QList<MusicArtist *> &newArtists) {
  if (m_artists == newArtists) {
    return;
  }
  m_artists = newArtists;
  emit artistsChanged();
}

QDate MusicAlbum::releaseDate() const {
  return m_releaseDate;
}

void MusicAlbum::setReleaseDate(const QDate &newReleaseDate) {
  if (m_releaseDate == newReleaseDate) {
    return;
  }
  m_releaseDate = newReleaseDate;
  emit releaseDateChanged();
}

QString MusicAlbum::albumName() const {
  return m_albumName;
}

void MusicAlbum::setAlbumName(const QString &newAlbumName) {
  if (m_albumName == newAlbumName) {
    return;
  }
  m_albumName = newAlbumName;
  emit albumNameChanged();
}

QString MusicArtist::artistName() const {
  return m_artistName;
}

void MusicArtist::setArtistName(const QString &newArtistName) {
  if (m_artistName == newArtistName) {
    return;
  }
  m_artistName = newArtistName;
  emit artistNameChanged();
}

MusicAlbum *MusicInfo::album() const {
  return m_album;
}

void MusicInfo::setAlbum(MusicAlbum *newAlbum) {
  if (m_album == newAlbum) {
    return;
  }
  m_album = newAlbum;
  emit albumChanged();
}

QString MusicInfo::songName() const {
  return m_songName;
}

void MusicInfo::setSongName(const QString &newSongName) {
  if (m_songName == newSongName) {
    return;
  }
  m_songName = newSongName;
  emit songNameChanged();
}
