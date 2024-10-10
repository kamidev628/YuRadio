import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Window

Dialog {
    id: root

    margins: 5
    modal: false

    Material.roundedScale: Material.NotRounded
    standardButtons: Dialog.Ok

    property int acceptedHours
    property int acceptedMinutes

    signal acceptedInterval(int hours, int minutes)

    onAccepted: {
        acceptedHours = hoursTumbler.currentIndex;
        acceptedMinutes = minutesTumbler.currentIndex;
        acceptedInterval(acceptedHours, acceptedMinutes);
    }

    contentItem: RowLayout {
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
