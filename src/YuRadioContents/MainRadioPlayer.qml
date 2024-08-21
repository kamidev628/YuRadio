pragma Singleton

import QtQuick
import Main

RadioPlayer {
    id: root

    property var currentItem

    onCurrentItemChanged: {
        AppSettings.lastStation = currentItem;
        const newMediaItem = constructMediaItem()

        if (currentItem) {
            newMediaItem.artworkUri = currentItem.favicon;
            newMediaItem.author = currentItem.name;
            newMediaItem.source = currentItem.url_resolved;
        }

        mediaItem = newMediaItem
        Qt.callLater(play);
    }
}
