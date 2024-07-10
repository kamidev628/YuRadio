#include "musicinfoprovider.h"

MusicInfoProvider::MusicInfoProvider(QObject *parent)
    : QObject(parent), m_state(Done) {}

MusicInfo *MusicInfoProvider::musicInfo() const {
  return m_musicInfo;
}

void MusicInfoProvider::setMusicInfo(MusicInfo *newMusicInfo) {
  if (m_musicInfo == newMusicInfo) {
    return;
  }

  delete m_musicInfo;
  m_musicInfo = newMusicInfo;

  if (m_musicInfo) {
    m_musicInfo->setParent(this);
  }

  emit musicInfoChanged();
}

MusicInfoProvider::State MusicInfoProvider::state() const {
  return m_state;
}

void MusicInfoProvider::setState(const State &newState) {
  if (m_state == newState) {
    return;
  }
  m_state = newState;
  emit stateChanged();
}
