import QtQml
import QtQuick.Controls

import YuRadioContents

Label {
    id: root

    property alias fontPointSize: scalableFontPicker.fontPointSize

    ScalableFontPicker {
        id: scalableFontPicker
    }
}
