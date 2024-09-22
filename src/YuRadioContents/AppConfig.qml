pragma Singleton

import QtQuick

QtObject {
    readonly property bool isPortrait: Screen.width < Screen.height
    readonly property bool isLandscape: !isPortrait
    readonly property bool isDarkTheme: AppSettings.theme === "Dark"
    readonly property bool isMobile: Qt.platform.os == "android" || Qt.platform.os == "ios"
    readonly property bool trayIconAvailable: AppConfig_trayIconAvailable
    readonly property int portraitLayoutWidth: 980
}
