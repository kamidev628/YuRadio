pragma Singleton

import QtQuick
import QtCore

Settings {
    id: settings

    property int desktopLayoutWidth: 1000
    property var lastStation
    property var initialPage: App.Page.Search
    property string language
    property string radioBrowserBaseUrl
    property string theme: Qt.styleHints.colorScheme === Qt.Dark ? "Dark" : "Light"
    readonly property bool isDarkTheme: theme === "Dark"
}
