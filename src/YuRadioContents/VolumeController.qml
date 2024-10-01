import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root

    property alias volume: volumeSlider.value
    property int orientation: Qt.Horizontal

    implicitWidth: volumeController.implicitWidth
    implicitHeight: volumeController.implicitHeight

    GridLayout {
        id: volumeController

        anchors.fill: parent

        rowSpacing: 0
        columnSpacing: 0
        flow: root.orientation == Qt.Horizontal ? GridLayout.LeftToRight : GridLayout.TopToBottom

        property bool muted: false
        property real lastVolume: volumeSlider.value

        states: [
            State {
                name: "vertical"
                when: root.orientation == Qt.Vertical

                PropertyChanges {
                    volumeButton.Layout.row: 1
                    volumeButton.Layout.column: 0

                    volumeSlider.Layout.row: 0
                    volumeSlider.Layout.column: 0
                }
            },
            State {
                name: "horizontal"
                when: root.orientation == Qt.Horizontal

                PropertyChanges {
                    volumeButton.Layout.row: 0
                    volumeButton.Layout.column: 0

                    volumeSlider.Layout.row: 0
                    volumeSlider.Layout.column: 1
                }
            }
        ]

        Button {
            id: volumeButton

            text: volumeController.muted ? qsTr("Unmute") : qsTr("Mute")
            display: AbstractButton.IconOnly
            flat: true

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: implicitHeight

            onClicked: {
                volumeController.muted = !volumeController.muted;
                if (!volumeController.muted) {
                    if (volumeController.lastVolume) {
                        volumeSlider.value = volumeController.lastVolume;
                    } else {
                        volumeSlider.value = 1;
                    }
                } else {
                    volumeSlider.value = 0;
                }
            }

            icon.source: volumeController.muted ? "images/volume-mute.svg" : "images/volume.svg"
        }

        Slider {
            id: volumeSlider

            Layout.fillWidth: true
            Layout.fillHeight: true

            orientation: root.orientation
            Accessible.name: qsTr("Volume")

            from: 0
            to: 1
            value: 1

            onMoved: {
                volumeController.lastVolume = value;
            }
            onValueChanged: {
                volumeController.muted = !value;
            }
        }
    }
}
