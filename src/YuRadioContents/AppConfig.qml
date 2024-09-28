pragma Singleton

import QtQuick
import YuRadioContents

QtObject {
    readonly property bool isPortrait: Screen.width < Screen.height
    readonly property bool isLandscape: !isPortrait
    readonly property bool isDarkTheme: AppSettings.theme === "Dark"
    readonly property bool isMobile: Qt.platform.os == "android" || Qt.platform.os == "ios"
    readonly property bool trayIconAvailable: AppConfig_trayIconAvailable
    readonly property int portraitLayoutWidth: 800

    function getScaledFont(desiredFontPointSize: int): int {
        return Math.floor(desiredFontPointSize * AppSettings.fontScale);
    }

    function isSmallSize(size: int): bool {
        return size <= AppSettings.smallSize
    }

    function isMediumSize(width: int): bool {
        return AppSettings.smallSize < width && width <= AppSettings.mediumSize
    }

    function isLargeSize(width: int): bool {
        return AppSettings.mediumSize < width && width <= AppSettings.largeSize;
    }
}
