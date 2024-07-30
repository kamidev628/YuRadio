import QtQuick
import QtQuick.Controls

Item {
    id: root

    implicitHeight: icon.implicitHeight
    implicitWidth: icon.implicitWidth

    property alias icon: iconImage

    signal clicked

    IconImage {
        id: iconImage

        anchors.centerIn: parent
    }
    MouseArea {
        anchors.fill: parent
        focusPolicy: root.focusPolicy
        onClicked: {
            root.clicked();
        }
    }
}
