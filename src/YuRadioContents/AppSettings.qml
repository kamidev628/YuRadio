pragma Singleton

import QtQuick
import QtCore

Settings {
    id: settings

    property string radioBrowserBaseUrl
    property string initialPage: "Search"
    property string theme: Qt.styleHints.colorScheme === Qt.Dark ? "Dark" : "Light"
    readonly property bool isDarkTheme: theme === "Dark"
}
