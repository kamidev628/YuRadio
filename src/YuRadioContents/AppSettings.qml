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
    property bool enableSleepTimer: false

    property real fontScale: 1.0
    property real volume: 1.0

    property int sleepInterval: 10 * 60 * 1000 /* 10 minutes */

    property int smallSize: 480
    property int mediumSize: 768
    property int largeSize: 1024

    property string stationUuid
    property string locale
    property string startPage: "search" /* ["search", "bookmark", "history"] */
    property string pauseButtonBehaviour: "pause" /* ["pause", "stop"] */
    property string radioBrowserBaseUrl
    property string theme: Qt.styleHints.colorScheme === Qt.Dark ? "Dark" : "Light"

    property string historyPageView: "table" /* ["table", "list"] */
}
