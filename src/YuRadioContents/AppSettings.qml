pragma Singleton

import QtQuick
import QtCore

Settings {
    id: settings

    property bool enableSelectionAnimation: true
    property bool showMessagesInTray: true
    property bool showIconInTray: true
    property bool resumePlaybackWhenNetworkRestored: true
    property bool enableBottomBarBlur: true

    property real fontScale: 1.0
    property real volume: 1.0

    property int initialPage: App.Page.Search

    property int smallSize: 480
    property int mediumSize: 768
    property int largeSize: 1024

    property string stationUuid
    property string locale
    property string pauseButtonBehaviour: "pause"
    property string radioBrowserBaseUrl
    property string theme: Qt.styleHints.colorScheme === Qt.Dark ? "Dark" : "Light"
}
