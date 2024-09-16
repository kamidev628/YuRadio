#ifndef LINUXRADIOCONTROLLER_H
#define LINUXRADIOCONTROLLER_H

#include "basicradiocontroller.h"

class MprisPlayer;

class LinuxRadioController : public BasicRadioController {
  Q_OBJECT

public:
  explicit LinuxRadioController(QObject *parent = nullptr);

  void setMediaItem(const MediaItem &mediaItem) override;
  bool canHandleMediaKeys() const override;

  void toggle();

private:
  MprisPlayer *m_mprisPlayer;
};

#endif /* !LINUXRADIOCONTROLLER_H */
