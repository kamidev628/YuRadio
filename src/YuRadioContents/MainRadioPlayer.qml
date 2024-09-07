pragma Singleton

import QtQuick
import Main

RadioPlayer {
    id: root

    property var currentItem

    volume: AppSettings.volume
    onVolumeChanged: {
        AppSettings.volume = volume;
    }

    onCurrentItemChanged: {
        const newMediaItem = constructMediaItem();
        if (currentItem) {
            newMediaItem.artworkUri = currentItem.favicon;
            newMediaItem.author = currentItem.name;
            newMediaItem.source = currentItem.url_resolved;
            AppSettings.stationUuid = currentItem.stationuuid;
        } else {
            AppSettings.stationUuid = "";
        }
        mediaItem = newMediaItem;
    }
}
