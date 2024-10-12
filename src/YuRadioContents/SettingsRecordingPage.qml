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

            ScalableLabel {
                id: recordingNameLabel

                Layout.topMargin: 5
                Layout.fillWidth: true

                text: qsTr("Name format")
                wrapMode: Text.Wrap
            }

            ScalableComboBox {
                id: recordingNameCombo

                implicitContentWidthPolicy: ComboBox.WidestText
                textRole: "text"

                model: [
                    {
                        text: "station_datetime",
                        field: AudioStreamRecorder.StationDateTime,
                        visible: root.audioRecorder.recordingPolicy !== AudioStreamRecorder.SaveRecordingWhenStreamTitleChanges
                    },
                    {
                        text: "station_trackname_datetime",
                        field: AudioStreamRecorder.StationTrackNameDateTime,
                        visible: root.audioRecorder.recordingPolicy === AudioStreamRecorder.SaveRecordingWhenStreamTitleChanges
                    },
                    {
                        text: "trackname_datetime",
                        field: AudioStreamRecorder.TrackNameDateTime,
                        visible: root.audioRecorder.recordingPolicy === AudioStreamRecorder.SaveRecordingWhenStreamTitleChanges
                    },
                ].filter(x => x.visible)

                Component.onCompleted: {
                    currentIndex = model.findIndex(x => x.field === root.audioRecorder.recordingNameFormat);
                }

                onCurrentValueChanged: {
                    if (currentValue) {
                        AppSettings.recordingNameFormat = currentValue.field;
                    }
                }
            }

            ScalableLabel {
                id: recordingPolicyLabel

                Layout.topMargin: 5
                Layout.fillWidth: true

                text: qsTr("Recording policy")
                wrapMode: Text.Wrap
            }

            ScalableComboBox {
                id: recordingPolicyCombo

                implicitContentWidthPolicy: ComboBox.WidestText
                textRole: "text"
                model: [
                    {
                        text: qsTr("No recording policy"),
                        field: AudioStreamRecorder.NoRecordingPolicy
                    },
                    {
                        text: qsTr("Save recording when stream title changes"),
                        field: AudioStreamRecorder.SaveRecordingWhenStreamTitleChanges
                    }
                ]

                Component.onCompleted: {
                    currentIndex = model.findIndex(x => x.field === root.audioRecorder.recordingPolicy);
                }

                onActivated: {
                    AppSettings.recordingPolicy = currentValue.field;
                }
            }

            ScalableButton {
                Layout.fillWidth: true

                text: root.audioRecorder.recording ? qsTr("Stop recording") : qsTr("Start recording")
                onClicked: {
                    if (root.audioRecorder.recording) {
                        root.audioRecorder.stop();
                    } else {
                        root.audioRecorder.record();
                    }
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
