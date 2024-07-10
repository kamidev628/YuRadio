#ifndef MUSICALBUM_H
#define MUSICALBUM_H

#include <QDate>
#include <QObject>
#include <QUrl>
#include <QtQml>

class MusicArtist : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString artistName READ artistName WRITE setArtistName NOTIFY
               artistNameChanged FINAL)
  QML_ELEMENT

public:
  MusicArtist(QObject *parent = nullptr);

  QString artistName() const;
  void setArtistName(const QString &newArtistName);

signals:
  void artistNameChanged();

private:
  QString m_artistName;
};

class MusicAlbum : public QObject {
  Q_OBJECT
  Q_PROPERTY(QUrl albumImageUrl READ albumImageUrl WRITE setAlbumImageUrl NOTIFY
               albumImageUrlChanged FINAL)
  Q_PROPERTY(QList<MusicArtist *> artists READ artists WRITE setArtists NOTIFY
               artistsChanged FINAL)
  Q_PROPERTY(QDate releaseDate READ releaseDate WRITE setReleaseDate NOTIFY
               releaseDateChanged FINAL)
  Q_PROPERTY(QString albumName READ albumName WRITE setAlbumName NOTIFY
               albumNameChanged FINAL)
  QML_ELEMENT

public:
  MusicAlbum(QObject *parent = nullptr);

  void addArtist(MusicArtist *artist);

  QUrl albumImageUrl() const;
  void setAlbumImageUrl(const QUrl &newAlbumImageUrl);

  QList<MusicArtist *> artists() const;
  void setArtists(const QList<MusicArtist *> &newArtists);

  QDate releaseDate() const;
  void setReleaseDate(const QDate &newReleaseDate);

  QString albumName() const;
  void setAlbumName(const QString &newAlbumName);

signals:
  void albumImageUrlChanged();
  void artistsChanged();
  void releaseDateChanged();
  void albumNameChanged();

private:
  QString m_albumName;
  QDate m_releaseDate;
  QUrl m_albumImageUrl;

  QList<MusicArtist *> m_artists;
};

class MusicInfo : public QObject {
  Q_OBJECT
  Q_PROPERTY(
    MusicAlbum *album READ album WRITE setAlbum NOTIFY albumChanged FINAL)
  Q_PROPERTY(QString songName READ songName WRITE setSongName NOTIFY
               songNameChanged FINAL)
  QML_ELEMENT

public:
  MusicInfo(QObject *parent = nullptr);

  MusicAlbum *album() const;
  void setAlbum(MusicAlbum *newAlbum);

  QString songName() const;
  void setSongName(const QString &newSongName);

signals:
  void albumChanged();
  void songNameChanged();

private:
  MusicAlbum *m_album = nullptr;
  QString m_songName;
};

#endif /* !MUSICALBUM_H */
