import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window

import YuRadioContents

Dialog {
    id: root

    required property int sleepTimerLeftInterval

    property int leftSleepHours: Math.floor(sleepTimerLeftInterval / 1000 / 60 / 60)
    property int leftSleepMinutes: sleepTimerLeftInterval / 1000 / 60 % 60

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
        RowLayout {
            Layout.topMargin: 10
            Layout.fillWidth: true
            Layout.minimumWidth: 200

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

        ScalableLabel {
            Layout.topMargin: 5
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            enabled: AppSettings.enableSleepTimer
            /* NOTE: Is it possible to internationalize? */
            text: `${root.leftSleepHours < 10 ? "0" : ""}${root.leftSleepHours}:${root.leftSleepMinutes < 10 ? "0" : ""}${root.leftSleepMinutes}`

            wrapMode: Text.Wrap
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
            textFormat: Text.PlainText

            opacity: 1.0 - Math.abs(Tumbler.displacement) / (Tumbler.tumbler.visibleItemCount / 2)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}
