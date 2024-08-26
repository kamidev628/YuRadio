pragma Singleton

import QtQuick
import QtCore

Settings {
    id: settings

    readonly property bool isPortrait: Screen.width < Screen.height
    readonly property bool isLandscape: !isPortrait
    readonly property bool isDarkTheme: theme === "Dark"
    readonly property int portraitLayoutWidth: 980 

    property bool enableSelectionAnimation: true
    property bool isMobile: Qt.platform.os == "android" || Qt.platform.os == "ios"
    property real volume: 1.0
    property var lastStation
    property var initialPage: App.Page.Search
    property string locale
    property string radioBrowserBaseUrl
    property string theme: Qt.styleHints.colorScheme === Qt.Dark ? "Dark" : "Light"
}
