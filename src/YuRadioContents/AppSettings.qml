pragma Singleton

import QtQuick
import QtCore

Settings {
    id: settings

    property bool enableSelectionAnimation: true
    property bool isMobile: Qt.platform.os == "android" || Qt.platform.os == "ios"
    property int desktopLayoutWidth: 1000
    property var lastStation
    property var initialPage: App.Page.Search
    property string locale
    property string radioBrowserBaseUrl
    property string theme: Qt.styleHints.colorScheme === Qt.Dark ? "Dark" : "Light"
    readonly property bool isDarkTheme: theme === "Dark"
}
