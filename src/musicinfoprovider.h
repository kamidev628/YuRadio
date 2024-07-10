#ifndef MUSICINFOPROVIDER_H
#define MUSICINFOPROVIDER_H

#include "musicinfo.h"

#include <QtQmlIntegration>

class MusicInfoProvider : public QObject {
  Q_OBJECT
  Q_PROPERTY(MusicInfo *musicInfo READ musicInfo NOTIFY musicInfoChanged FINAL)
  Q_PROPERTY(State state READ state NOTIFY stateChanged FINAL)

public:
  MusicInfoProvider(QObject *parent = nullptr);
  ~MusicInfoProvider() override = default;

  enum State { Done = 0, Failed, Processing };

  Q_ENUM(State);

  Q_INVOKABLE virtual void provide(const QString &searchString) = 0;

  MusicInfo *musicInfo() const;
  State state() const;

signals:
  void musicInfoChanged();
  void stateChanged();

protected:
  void setMusicInfo(MusicInfo *newMusicInfo);
  void setState(const State &newState);

private:
  MusicInfo *m_musicInfo = nullptr;
  State m_state;
};

#endif /* !MUSICINFOPROVIDER_H */
