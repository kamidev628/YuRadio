import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root

    implicitWidth: volumeController.implicitWidth
    implicitHeight: volumeController.implicitHeight

    readonly property real volume: volumeSlider.value
    readonly property bool muted: !volume 

    RowLayout {
        id: volumeController

        anchors.fill: parent
        spacing: 0

        property bool muted: false
        property real lastVolume: 1.0

        Button {
            id: volumeButton
            display: AbstractButton.IconOnly
            flat: true

            onClicked: {
                volumeController.muted = !volumeController.muted;
                if (!volumeController.muted) {
                    volumeSlider.value = volumeController.lastVolume;
                } else {
                    volumeSlider.value = 0;
                }
            }

            icon.source: volumeController.muted ? "images/volume-mute.svg" : "images/volume.svg"
        }

        Slider {
            id: volumeSlider
            Layout.fillWidth: true

            from: 0
            to: 1
            value: 1

            onMoved: {
                volumeController.lastVolume = value;
                volumeController.muted = !value;
            }
        }
    }
}
