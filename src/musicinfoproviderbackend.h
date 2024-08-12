#ifndef MUSICINFOPROVIDERBACKEND_H
#define MUSICINFOPROVIDERBACKEND_H

#include <QtQmlIntegration>

struct MusicInfoDetails {
  QStringList artistNames;
  QList<QUrl> coverUrls;
  QDate releaseDate;
  QUrl trackUrl;
  QString albumName;
  QString songName;
};

class MusicInfoProviderBackend : public QObject {
  Q_OBJECT

public:
  MusicInfoProviderBackend(QObject *parent = nullptr);
  ~MusicInfoProviderBackend() override = default;

  virtual void requestMusicInfo(const QString &searchString) = 0;
  virtual QString backendName() const = 0;

signals:
  void musicInformation(const MusicInfoDetails &musicInfoDetails);
  void errorOccurred();
};

#endif /* !MUSICINFOPROVIDERBACKEND_H */
