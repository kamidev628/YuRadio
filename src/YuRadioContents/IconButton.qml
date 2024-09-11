import QtQuick
import QtQuick.Controls

Item {
    id: root

    property alias icon: iconImage

    signal clicked

    implicitHeight: icon.implicitHeight
    implicitWidth: icon.implicitWidth

    IconImage {
        id: iconImage

        anchors.centerIn: parent

        antialiasing: false
        smooth: false
    }

    MouseArea {
        anchors.fill: parent

        focusPolicy: root.focusPolicy
        onClicked: {
            root.clicked();
        }
    }
}
