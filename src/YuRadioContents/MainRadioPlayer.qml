pragma Singleton

import QtQuick
import Main

RadioPlayer {
    id: root

    property var currentItem

    onCurrentItemChanged: {
        AppSettings.lastStation = currentItem;
    }

    source: currentItem ? currentItem.url_resolved : ""
}
