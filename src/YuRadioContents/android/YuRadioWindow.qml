import QtQuick
import QtQuick.Controls

import YuRadioContents
import Main

ApplicationWindow {
    property int bottomMargin: AndroidKeyboard.height / Screen.devicePixelRatio

    Binding {
        target: AndroidStatusBar
        property: "color"
        value: AppColors.headerColor
    }
}
