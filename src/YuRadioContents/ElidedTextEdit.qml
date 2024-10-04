import QtQuick
import QtQuick.Controls.Material

TextInput {
    id: root

    property alias fontPointSize: scalableFontPicker.fontPointSize
    property string fullText

    property int fullTextImplicitWidth: metrics.boundingRect.width
    property int fullTextImplicitHeight: metrics.boundingRect.height

    color: Material.foreground

    ScalableFontPicker {
        id: scalableFontPicker
    }

    text: activeFocus ? fullText : metrics.elidedText
    readOnly: true
    clip: true

    TextMetrics {
        id: metrics

        font: root.font
        text: root.fullText
        elide: Text.ElideRight
        elideWidth: root.width
    }
}
