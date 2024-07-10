import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

ApplicationWindow {
    id: root
    width: 500
    height: 400
    visible: true

    flags: Qt.Window | Qt.WindowSystemMenuHint | Qt.WindowTitleHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint | Qt.WindowStaysOnTopHint

    modality: Qt.NonModal

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20

        Text {
            id: error
            color: Material.color(Material.Red)
            font.pointSize: 20
            text: "Errors occurred"
        }

        Frame {
            id: errorFrame
            Layout.fillHeight: true
            Layout.fillWidth: true

            Flickable {
                id: flickable
                anchors.fill: parent
                clip: true
                contentWidth: parent.width
                contentHeight: warningsText.height
                Text {
                    id: warningsText
                    width: flickable.width
                    text: `${QmlWarnings}`
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
