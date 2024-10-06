import QtQuick
import QtQuick.Controls.Material

TextInput {
    id: root

    property alias fontPointSize: scalableFontPicker.fontPointSize

    readOnly: true
    clip: true

    color: Material.foreground

    ScalableFontPicker {
        id: scalableFontPicker
    }
}
