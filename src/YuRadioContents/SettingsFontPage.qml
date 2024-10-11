import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import YuRadioContents

Item {
    id: fontPage

    ColumnLayout {
        anchors {
            fill: parent
            leftMargin: 15
            topMargin: 15
            rightMargin: 15
        }

        Label {
            id: fontScaleLabel

            Layout.topMargin: 20

            property string translatedFontString: qsTr("Font scale")

            text: `${translatedFontString}: ${slider.value.toFixed(1)}`
            font.pointSize: 12
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: 12

            Label {
                text: qsTr("A")
                font.pixelSize: 14
                font.weight: 400
            }

            Slider {
                id: slider

                Layout.fillWidth: true
                Accessible.name: fontScaleLabel.translatedFontString

                snapMode: Slider.SnapAlways
                stepSize: 0.1
                from: 0.7
                value: AppSettings.fontScale
                to: 1.5

                onMoved: AppSettings.fontScale = value
            }

            Label {
                text: qsTr("A")
                font.pixelSize: 21
                font.weight: 400
            }
        }

        ScalableLabel {
            Layout.fillWidth: true
            text: qsTr("Sample Text")
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
