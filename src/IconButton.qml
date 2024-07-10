import QtQuick
import QtQuick.Controls

Item {
    id: root

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
