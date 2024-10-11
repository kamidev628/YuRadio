import QtQuick.Controls

CheckBox {
    property alias fontPointSize: scalableFontPicker.fontPointSize

    ScalableFontPicker {
        id: scalableFontPicker
    }
}
