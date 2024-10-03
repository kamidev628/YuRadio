import QtQuick
import QtQuick.Controls.Material

TextInput {
    id: root

    property alias fontPointSize: scalableFontPicker.fontPointSize
    property string fullText

    color: Material.foreground

    ScalableFontPicker {
        id: scalableFontPicker
    }

    text: activeFocus ? fullText : metrics.elidedText
    readOnly: true

    TextMetrics {
        id: metrics

        font: root.font
        text: root.fullText
        elide: Text.ElideRight
        elideWidth: root.width
    }
}
