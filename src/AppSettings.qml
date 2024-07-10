pragma Singleton

import QtQuick
import QtCore

Settings {
    id: settings

    property string theme: Qt.styleHints.colorScheme === Qt.Dark ? "Dark" : "Light"
    readonly property bool isDarkTheme: theme === "Dark"
}
