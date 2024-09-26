import QtQuick
import QtQuick.Controls

ComboBox {
    property alias fontPointSize: scalableFontPicker.fontPointSize

    popup.font.pointSize: font.pointSize

    ScalableFontPicker {
        id: scalableFontPicker
    }
}
