import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import YuRadioContents
import Main

ScrollView {
    id: root

    required property AudioStreamRecorder audioRecorder

    contentWidth: -1
    contentHeight: root.implicitHeight

    Binding {
        target: root.contentItem
        property: "boundsBehavior"
        value: Flickable.StopAtBounds
    }

    Item {
        id: recordingsPageContents

        implicitHeight: columnLayout.implicitHeight
        implicitWidth: parent.width

        ColumnLayout {
            id: columnLayout

            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
                topMargin: 20
            }

            DirectoryPicker {
                recorder: root.audioRecorder
                Layout.fillWidth: true
            }

            ScalableButton {
                Layout.fillWidth: true

                text: qsTr("Start recording")
                onClicked: {
                    root.audioRecorder.record();
                }
            }

            Item {
                Layout.preferredHeight: 20
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
