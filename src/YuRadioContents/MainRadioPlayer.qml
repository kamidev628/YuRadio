pragma Singleton

import QtQuick
import Main

RadioPlayer {
    id: root

    property var currentItem

    onCurrentItemChanged: {
        AppSettings.lastStation = currentItem;
        if (currentItem) {
            mediaItem.artworkUri = currentItem.favicon;
            mediaItem.author = currentItem.name;
            mediaItem.source = currentItem.url_resolved;
        }
        Qt.callLater(play);
    }

    mediaItem: MediaItem {}
}
