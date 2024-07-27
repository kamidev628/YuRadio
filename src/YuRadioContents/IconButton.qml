import QtQuick
import QtQuick.Controls

Item {
    id: root

    implicitHeight: icon.implicitHeight
    implicitWidth: icon.implicitWidth

    property alias icon: searchIcon

    signal clicked

    IconImage {
        id: searchIcon

        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.clicked();
            }
        }
    }
}
