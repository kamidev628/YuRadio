import QtQuick
import QtQuick.Controls.Material

Item {
    id: root

    readonly property bool isSearching: searchInput.activeFocus
    required property real availableWidth

    property alias searchInput: searchInput
    property alias searchIcon: searchButton.icon
    property alias searchButton: searchButton

    Rectangle {
        id: background
        anchors {
            fill: parent
            bottomMargin: 6
            topMargin: 6
        }

        color: "transparent"
        radius: height / 2
    }

    states: [
        State {
            name: "searching"
            when: root.isSearching

            PropertyChanges {
                background.color: root.Material.color(Material.Grey, Material.Shade100)
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
                target: background
                properties: "color"
                duration: 200
            }
            PropertyAnimation {
                target: searchButton
                properties: "icon.color"
                duration: 200
            }
            PropertyAnimation {
                target: searchInput
                properties: "opacity"
                duration: 400
            }
        }
    ]

    ToolButton {
        id: searchButton

        icon.source: 'images/search.svg'
        focusPolicy: Qt.NoFocus

        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
        }

        onClicked: {
            if (!searchInput.activeFocus) {
                searchInput.forceActiveFocus();
            }
        }
    }

    TextInput {
        id: searchInput
        opacity: 0
        clip: true

        anchors {
            verticalCenter: parent.verticalCenter
            leftMargin: -10
            left: searchButton.right
            right: parent.right
        }

        width: parent.width
    }
}
