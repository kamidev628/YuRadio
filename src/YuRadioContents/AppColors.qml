pragma Singleton

import QtQuick
import QtQuick.Controls.Material

import YuRadioContents

QtObject {
    id: root

    property color headerColor

    property color toolButtonColor: AppConfig.isDarkTheme ? "#e8eaed" : "transparent"
    property color toolBarMorphColor: AppConfig.isDarkTheme ? Material.background.lighter(1.2) : "#f1ebf4"
    property color searchBarColor: Material.background.lighter(AppConfig.isDarkTheme ? 0.3 : headerColor !== toolBarMorphColor ? 0.9 : 1.3)
}
