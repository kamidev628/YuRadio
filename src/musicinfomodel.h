#ifndef MUSICINFOMODEL_H
#define MUSICINFOMODEL_H

#include <QObject>

#include "musicinfoproviderbackend.h"

class MusicInfo : public QObject {
  Q_OBJECT
  Q_PROPERTY(
    QString songName READ songName WRITE setSongName NOTIFY dataChanged)
  Q_PROPERTY(QStringList artistNames READ artistNames WRITE setArtistNames
               NOTIFY dataChanged)
  Q_PROPERTY(
    QList<QUrl> coverUrls READ coverUrls WRITE setCoverUrls NOTIFY dataChanged)
  Q_PROPERTY(
    QDate releaseDate READ releaseDate WRITE setReleaseDate NOTIFY dataChanged)
  Q_PROPERTY(
    QString albumName READ albumName WRITE setAlbumName NOTIFY dataChanged)
  QML_ANONYMOUS

public:
  explicit MusicInfo(QObject *parent = nullptr);
  MusicInfo(const MusicInfo &other);
  MusicInfo(const MusicInfoDetails &other);

  QString songName() const;
  void setSongName(const QString &newSongName);

  QStringList artistNames() const;
  void setArtistNames(const QStringList &newArtistNames);

  QList<QUrl> coverUrls() const;
  void setCoverUrls(const QList<QUrl> &newCoverUrls);

  QDate releaseDate() const;
  void setReleaseDate(const QDate &newReleaseDate);

  QString albumName() const;
  void setAlbumName(const QString &newAlbumName);

signals:
  void dataChanged();

private:
  QStringList m_artistNames;
  QList<QUrl> m_coverUrls;
  QString m_songName;
  QString m_albumName;
  QDate m_releaseDate;
};

class MusicInfoModel : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString searchTerm READ searchTerm WRITE setSearchTerm NOTIFY
               searchTermChanged)
  Q_PROPERTY(Status status READ status NOTIFY statusChanged)
  Q_PROPERTY(MusicInfo *musicInfo READ musicInfo NOTIFY musicInfoChanged)
  QML_ELEMENT

public:
  explicit MusicInfoModel(QObject *parent = nullptr);

  enum Status {
    Null = 0,
    Ready,
    Loading,
    Error,
  };
  Q_ENUM(Status)

  QString searchTerm() const;
  void setSearchTerm(const QString &newSearchTerm);

  Q_INVOKABLE void refresh();
  Q_INVOKABLE bool hasValidSearchTerm() const;

  Status status() const;
  MusicInfo *musicInfo() const;

signals:
  void searchTermChanged();
  void musicInfoChanged();
  void statusChanged();

protected:
  void registerBackend(qsizetype index);
  void requestMusicInfo();
  void deregisterCurrentBackend();
  void switchToNextBackend();
  void setStatus(Status status);

private:
  void handleMusicInformationDetails(const MusicInfoDetails &details);

private:
  MusicInfoProviderBackend *m_currentBackend = nullptr;
  QList<MusicInfoProviderBackend *> m_supportedBackends;
  qsizetype m_currentBackendIndex;

  MusicInfo *m_musicInfo = nullptr;
  QString m_searchTerm;
  Status m_status;
};

#endif /* !MUSICINFOMODEL_H */
