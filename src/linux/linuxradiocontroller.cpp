#include <MprisPlayer>

#include "linuxradiocontroller.h"

using namespace Qt::StringLiterals;

static Mpris::PlaybackStatus
toMprisPlaybackStatus(RadioPlayer::PlaybackState state) {
  switch (state) {
    case RadioPlayer::StoppedState:
      return Mpris::Stopped;
    case RadioPlayer::PlayingState:
      return Mpris::Playing;
    case RadioPlayer::PausedState:
      return Mpris::Paused;
  }
}

LinuxRadioController::LinuxRadioController(QObject *parent)
    : BasicRadioController(parent), m_mprisPlayer(new MprisPlayer(this)) {
  /* Will register org.mpris.MediaPlayer2.yuradio service */
  m_mprisPlayer->setServiceName(u"yuradio"_s);
  m_mprisPlayer->setIdentity(u"YuRadio"_s);
  m_mprisPlayer->setCanPlay(true);
  m_mprisPlayer->setCanPause(true);
  m_mprisPlayer->setCanControl(false);

  connect(m_mprisPlayer, &MprisPlayer::playRequested, this,
          &LinuxRadioController::play);
  connect(m_mprisPlayer, &MprisPlayer::stopRequested, this,
          &LinuxRadioController::stop);
  connect(m_mprisPlayer, &MprisPlayer::pauseRequested, this,
          &LinuxRadioController::pause);
  connect(m_mprisPlayer, &MprisPlayer::playPauseRequested, this,
          &LinuxRadioController::toggle);
  connect(m_mprisPlayer, &MprisPlayer::volumeRequested, this,
          [this](double volume) { setVolume(static_cast<float>(volume)); });

  connect(m_mediaPlayer, &QMediaPlayer::mediaStatusChanged, this,
          [this](QMediaPlayer::MediaStatus status) {
    if (status == QMediaPlayer::LoadedMedia) {
      m_mprisPlayer->setCanControl(true);
    }
  });

  connect(this, &LinuxRadioController::volumeChanged, m_mprisPlayer, [this]() {
    m_mprisPlayer->setVolume(static_cast<double>(volume()));
  });
  connect(this, &LinuxRadioController::playbackStateChanged, m_mprisPlayer,
          [this]() {
    m_mprisPlayer->setPlaybackStatus(toMprisPlaybackStatus(playbackState()));
  });
  connect(this, &LinuxRadioController::streamTitleChanged, this, [this]() {
    QVariantMap metadata = m_mprisPlayer->metadata();
    metadata[u"xesam:title"_s] = streamTitle();
    m_mprisPlayer->setMetadata(metadata);
  });
}

void LinuxRadioController::setMediaItem(const MediaItem &mediaItem) {
  QVariantMap mprisMetadata;

  mprisMetadata[u"mpris:length"_s] = -1;
  mprisMetadata[u"mpris:artUrl"_s] = mediaItem.artworkUri;
  mprisMetadata[u"xesam:artist"_s] = mediaItem.author;
  mprisMetadata[u"xesam:title"_s] = u"YuRadio"_s;

  m_mprisPlayer->setMetadata(mprisMetadata);
  m_mprisPlayer->setCanControl(false);

  BasicRadioController::setMediaItem(mediaItem);
}

bool LinuxRadioController::canHandleMediaKeys() const {
  return true;
}
