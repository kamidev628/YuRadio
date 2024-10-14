pragma Singleton

import QtQuick
import YuRadioContents

QtObject {
    readonly property bool isPortrait: Screen.width < Screen.height
    readonly property bool isLandscape: !isPortrait
    readonly property bool isDarkTheme: AppSettings.theme === "Dark"
    readonly property bool isMobile: Qt.platform.os == "android" || Qt.platform.os == "ios"
    readonly property bool trayIconAvailable: AppConfig_trayIconAvailable
    readonly property bool networkInformationBackendAvailable: AppConfig_networkInformationBackendAvailable
    readonly property int portraitLayoutWidth: 700
    readonly property int detachBottomBarWidth: 1000
    readonly property int radioStationInfoPanelWidth: 250
    readonly property int minimumWindowWidth: 300
    readonly property int minimumWindowHeight: 300
    readonly property int searchBarMaximumWidth: 300

    function getScaledFont(desiredFontPointSize: int): int {
        return Math.floor(desiredFontPointSize * AppSettings.fontScale);
    }

    function isSmallSize(size: int): bool {
        return size <= AppSettings.smallSize;
    }

    function isMediumSize(width: int): bool {
        return AppSettings.smallSize < width && width <= AppSettings.mediumSize;
    }

    function isLargeSize(width: int): bool {
        return AppSettings.mediumSize < width;
    }
}
