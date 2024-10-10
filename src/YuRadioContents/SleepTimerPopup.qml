import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window

import YuRadioContents

Dialog {
    id: root

    margins: 5
    modal: AppConfig.isSmallSize(ApplicationWindow.window.width)

    anchors.centerIn: AppConfig.isSmallSize(ApplicationWindow.window.width) ? Overlay.overlay : undefined

    standardButtons: Dialog.Ok

    contentItem: ColumnLayout {
        ScalableLabel {
            Layout.topMargin: 5
            Layout.fillWidth: true

            enabled: AppSettings.enableSleepTimer

            property string timeTemplateString: intervalPickerPopup.acceptedHours > 0 ? qsTr("%1 hrs %2 min").arg(intervalPickerPopup.acceptedHours).arg(intervalPickerPopup.acceptedMinutes) : qsTr("%1 min").arg(intervalPickerPopup.acceptedMinutes)

            text: qsTr("Sleep interval: %1").arg(timeTemplateString)
            wrapMode: Text.Wrap
        }

        ScalableButton {
            Layout.topMargin: 5
            Layout.fillWidth: true

            enabled: AppSettings.enableSleepTimer

            text: qsTr("Pick interval")
            onClicked: {
                intervalPickerPopup.open();
            }

            IntervalPickerPopup {
                id: intervalPickerPopup

                property int acceptedIntervalMilliseconds: (acceptedHours * 60 + acceptedMinutes) * 60 * 1000

                acceptedHours: Math.floor(AppSettings.sleepInterval / 1000 / 60 / 60)
                acceptedMinutes: Math.floor(AppSettings.sleepInterval / 1000 / 60 % 60)

                onAcceptedInterval: (hours, minutes) => {
                    if (acceptedIntervalMilliseconds > 0) {
                        AppSettings.sleepInterval = acceptedIntervalMilliseconds;
                    } else {
                        AppSettings.enableSleepTimer = false;
                    }
                }
            }
        }

            ScalableButton {
                Layout.topMargin: 5
                Layout.fillWidth: true

                checkable: true
                checked: AppSettings.sleepInterval > 0
                text: checked ? qsTr("Disable sleep timer") : qsTr("Enable sleep timer")

                onClicked: {
                    AppSettings.enableSleepTimer = checked;
                }
            }
    }

    Component {
        id: tumblerDelegate

        ScalableLabel {
            function formatText(count, modelData) {
                var data = count === 12 ? modelData + 1 : modelData;
                return data.toString().length < 2 ? "0" + data : data;
            }

            text: formatText(Tumbler.tumbler.count, modelData)
            opacity: 1.0 - Math.abs(Tumbler.displacement) / (Tumbler.tumbler.visibleItemCount / 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
