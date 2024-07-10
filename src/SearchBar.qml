import QtQuick
import QtQuick.Controls.Material

Rectangle {
    id: root
    radius: height / 2

    color: "transparent"

    readonly property bool isSearching: searchInput.activeFocus
    required property real availableWidth

    property alias searchInput: searchInput
    property alias searchIcon: searchButton.icon

    states: [
        State {
            name: "searching"
            when: root.isSearching

            PropertyChanges {
                root.color: root.Material.color(Material.Grey, Material.Shade100)
            }
            PropertyChanges {
                root.implicitWidth: root.availableWidth
            }
            PropertyChanges {
                searchInput.opacity: 1.0
            }
            PropertyChanges {
                searchButton.icon.color: root.Material.color(Material.Grey, Material.Shade800)
            }
        }
    ]

    transitions: [
        Transition {
            to: "searching"
            reversible: true

            PropertyAnimation {
                target: root
                properties: "implicitWidth"
                duration: 350
                easing.type: Easing.InOutQuad
            }
            PropertyAnimation {
                target: root
                properties: "color"
                duration: 200
            }
            PropertyAnimation {
                target: searchButton.icon
                properties: "color"
                duration: 200
            }
            PropertyAnimation {
                target: searchInput
                properties: "opacity"
                duration: 400
            }
        }
    ]

    IconButton {
        id: searchButton

        icon.source: 'images/search.svg'
        icon.sourceSize: Qt.size(height, height)
        icon.color: Material.color(Material.Grey, Material.Shade50)

        anchors {
            top: parent.top
            left: parent.left
            bottom: parent.bottom

            leftMargin: 3
            topMargin: 1
            bottomMargin: 1
        }

        width: height

        onClicked: searchInput.forceActiveFocus()
    }

    TextInput {
        id: searchInput
        clip: true
        opacity: 0

        anchors {
            verticalCenter: parent.verticalCenter
            left: searchButton.right
            right: parent.right
        }

        width: parent.width
    }
}
