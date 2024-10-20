import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material

import YuRadioContents

Control {
    id: root

    readonly property bool isSearching: searchInput.activeFocus
    required property real maximumWidth

    property alias searchInput: searchInput
    property alias searchIcon: searchButton.icon
    property alias searchButton: searchButton

    function activate(): void {
        searchInput.forceActiveFocus();
    }

    property color backgroundColor: AppConfig.isPortraitLayout || isSearching ? AppColors.searchBarColor : "transparent"

    Accessible.name: qsTr("Search")

    Material.foreground: Material.primaryTextColor
    Material.background: backgroundColor

    bottomInset: 8
    topInset: 8
    topPadding: -8
    bottomPadding: -8

    Behavior on backgroundColor {
        ColorAnimation {
            duration: 500
        }
    }

    states: [
        State {
            name: "portraitLayout"
            extend: "searching"
            when: AppConfig.isPortraitLayout
        },
        State {
            name: "searching"
            when: root.isSearching

            PropertyChanges {
                searchInput.opacity: 1.0
                root.implicitWidth: root.maximumWidth
                removeTextButton.opacity: 1.0
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
                duration: 200
                easing.type: Easing.InOutQuad
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

    background: Rectangle {
        id: background

        color: root.Material.background
        radius: height / 2
    }

    contentItem: RowLayout {
        id: rowLayout

        clip: true

        ToolButton {
            id: searchButton

            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

            icon.source: 'images/search.svg'
            icon.color: AppColors.toolButtonColor

            focus: true
            focusPolicy: Qt.TabFocus

            onClicked: {
                if (!searchInput.activeFocus) {
                    searchInput.forceActiveFocus();
                }
            }
        }

        TextField {
            id: searchInput

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: -6
            Layout.rightMargin: -6

            focus: true
            focusPolicy: Qt.StrongFocus

            leftPadding: 0
            rightPadding: 0

            leftInset: 0
            rightInset: 0
            bottomInset: 0
            topInset: 0

            Accessible.searchEdit: true
            background.opacity: 0

            Material.foreground: root.Material.foreground
            EnterKey.type: Qt.EnterKeySearch

            opacity: 0
            visible: opacity > 0
        }

        ToolButton {
            id: removeTextButton

            Layout.alignment: Qt.AlignVCenter

            icon.source: 'images/close.svg'
            icon.color: searchButton.icon.color

            opacity: 0
            visible: opacity > 0
            enabled: searchInput.text.length > 0
            focus: true
            focusPolicy: Qt.TabFocus

            onClicked: {
                searchInput.clear();
            }
        }
    }
}
