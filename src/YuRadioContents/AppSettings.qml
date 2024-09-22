pragma Singleton

import QtQuick
import QtCore

Settings {
    id: settings

    property bool enableSelectionAnimation: true
    property bool showMessagesInTray: true
    property bool showIconInTray: true
    property real volume: 1.0
    property var initialPage: App.Page.Search
    property string stationUuid
    property string locale
    property string radioBrowserBaseUrl
    property string theme: Qt.styleHints.colorScheme === Qt.Dark ? "Dark" : "Light"
}
