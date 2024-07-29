pragma Singleton

import QtQuick
import Main

RadioPlayer {
    id: root

    property var currentItem: undefined

    source: currentItem ? currentItem.url_resolved : ""
}
