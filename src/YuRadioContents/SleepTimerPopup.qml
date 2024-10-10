import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window

import YuRadioContents

Dialog {
    id: root

    property int hours: hoursTumbler.currentIndex
    property int minutes: minutesTumbler.currentIndex
    property int milliseconds: (hours * 60 + minutes) * 60 * 1000

    onMillisecondsChanged: {
        if (milliseconds > 0) {
            AppSettings.sleepInterval = milliseconds;
        }
    }

    margins: 5
    modal: AppConfig.isSmallSize(ApplicationWindow.window.width)

    anchors.centerIn: Overlay.overlay

    standardButtons: Dialog.Ok

    contentItem: ColumnLayout {
        ScalableLabel {
            Layout.topMargin: 5
            Layout.fillWidth: true

            enabled: AppSettings.enableSleepTimer

            property string timeTemplateString: root.hours > 0 ? qsTr("%1 hrs %2 min").arg(root.hours).arg(root.minutes) : qsTr("%1 min").arg(root.minutes)

            text: qsTr("Sleep interval: %1").arg(timeTemplateString)
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.minimumWidth: 200

            enabled: AppSettings.enableSleepTimer

            Tumbler {
                id: hoursTumbler

                Layout.fillWidth: true
                Layout.minimumHeight: 50

                model: 24
                delegate: tumblerDelegate
            }

            Tumbler {
                id: minutesTumbler

                Layout.fillWidth: true
                Layout.minimumHeight: 50

                model: 60
                delegate: tumblerDelegate
            }
        }

        ScalableButton {
            Layout.topMargin: 5
            Layout.fillWidth: true

            text: AppSettings.enableSleepTimer ? qsTr("Disable sleep timer") : qsTr("Enable sleep timer")

            onClicked: {
                AppSettings.enableSleepTimer = !AppSettings.enableSleepTimer;
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
