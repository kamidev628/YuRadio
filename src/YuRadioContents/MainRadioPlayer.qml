pragma Singleton

import QtQuick
import Main
import YuRadioContents

RadioPlayer {
    id: root

    property radiostation currentItem

    volume: AppSettings.volume
    onVolumeChanged: {
        AppSettings.volume = volume;
    }

    onCurrentItemChanged: {
        const newMediaItem = constructMediaItem();
        if (currentItem.isValid()) {
            newMediaItem.artworkUri = currentItem.favicon;
            newMediaItem.author = currentItem.name;
            newMediaItem.source = currentItem.url;
            AppSettings.stationUuid = currentItem.uuid;
        } else {
            AppSettings.stationUuid = "";
        }
        mediaItem = newMediaItem;
    }
}
