import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Rectangle {
    id: root

    required property int index
    required property string favicon
    required property string name
    required property string tags
    required property string url_resolved

    width: ListView.view.width
    color: "transparent"

    implicitHeight: 100

    Image {
        id: radioImage
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: 5
            topMargin: 5
            bottomMargin: 5
        }
        source: root.favicon ? root.favicon : "images/radio.png"
        smooth: true
        width: height
    }

    Item {
        anchors {
            top: radioImage.top
            right: parent.right
            bottom: radioImage.bottom
            left: radioImage.right
            leftMargin: 10
            rightMargin: 20
        }

        ColumnLayout {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.name ? root.name : "Unknown Station"
                font.bold: true
                font.pointSize: 15
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.tags
                font.pointSize: 14
            }
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        onClicked: {
            root.ListView.view.currentIndex = root.index;
        }
    }
}
