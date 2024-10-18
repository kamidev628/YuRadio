pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls
import QtQuick.Layouts

import YuRadioContents

Drawer {
    id: root

    property bool expanded: false

    signal showBookmarksRequested
    signal showSearchRequested
    signal showSettingsRequested
    signal showAboutRequested
    signal showHistoryRequested

    function toggle() {
        if (AppConfig.isPortraitLayout) {
            if (!opened) {
                open();
            }
            expanded = !expanded;
        } else if (opened) {
            close();
        } else {
            open();
        }
    }

    width: Math.max(Math.min(parent.width, parent.height) * 2 / (modal ? 3 : 6), AppConfig.minimumWindowWidth - 50)
    height: parent.height
    clip: true

    Material.roundedScale: Material.NotRounded

    Connections {
        target: AppConfig

        function onIsPortraitLayoutChanged() {
            if (AppConfig.isPortraitLayout && !root.opened) {
                root.expanded = false;
                root.open();
            }
        }
    }

    StateGroup {
        states: [
            State {
                name: "iconOnly"
                when: !root.expanded && AppConfig.isPortraitLayout
                extend: "portraitLayout"

                PropertyChanges {
                    columnLayout.anchors.margins: 0
                    volumeController.orientation: Qt.Vertical
                    volumeController.Layout.bottomMargin: 10
                    listView.iconOnly: true
                    themeSwitchController.opacity: 0
                    themeSwitchController.scale: 0
                    profileImage.opacity: 0
                    root.width: 50
                }
            },
            State {
                name: "portraitLayout"
                when: AppConfig.isPortraitLayout

                PropertyChanges {
                    root.closePolicy: Popup.NoAutoClose
                    root.modal: false
                    root.interactive: false
                }
            }
        ]

        transitions: [
            Transition {
                to: "iconOnly"

                PropertyAnimation {
                    target: volumeController
                    property: "orientation"
                    duration: 0
                }
                PropertyAnimation {
                    target: themeSwitchController
                    property: "opacity,scale"
                    duration: 50
                }
                PropertyAnimation {
                    target: root
                    properties: "width"
                    duration: 300
                    easing.type: Easing.OutExpo
                }
                PropertyAnimation {
                    target: profileImage
                    properties: "opacity"
                    duration: 100
                }
            },
            Transition {
                PropertyAnimation {
                    target: themeSwitchController
                    property: "opacity,scale"
                    duration: 50
                }
                PropertyAnimation {
                    target: root
                    properties: "width"
                    duration: 300
                    easing.type: Easing.OutExpo
                }
                PropertyAnimation {
                    target: profileImage
                    properties: "opacity"
                    duration: 100
                }
            }
        ]
    }

    ColumnLayout {
        id: columnLayout

        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Image {
            id: profileImage

            Layout.preferredWidth: parent.width * 2 / 5
            Layout.preferredHeight: parent.width * 2 / 5
            Layout.minimumHeight: 50
            Layout.alignment: Qt.AlignHCenter

            fillMode: Image.PreserveAspectFit
            source: "images/shortwave.svg"
            asynchronous: true
            smooth: true
        }

        ListView {
            id: listView

            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.minimumHeight: 70

            property bool iconOnly: false

            focus: true

            currentIndex: -1
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollIndicator.vertical: ScrollIndicator {}

            model: ListModel {
                ListElement {
                    itemText: qsTr("Search")
                    iconSource: "images/search.svg"
                    triggered: () => {
                        root.showSearchRequested();
                    }
                }
                ListElement {
                    itemText: qsTr("Bookmarks")
                    iconSource: "images/bookmark.svg"
                    triggered: () => {
                        root.showBookmarksRequested();
                    }
                }
                ListElement {
                    itemText: qsTr("History")
                    iconSource: "images/history.svg"
                    triggered: () => {
                        root.showHistoryRequested();
                    }
                }
                ListElement {
                    itemText: qsTr("Settings")
                    iconSource: "images/settings.svg"
                    triggered: () => {
                        root.showSettingsRequested();
                    }
                }
                ListElement {
                    itemText: qsTr("About")
                    iconSource: "images/about.svg"
                    triggered: () => {
                        root.showAboutRequested();
                    }
                }
            }

            delegate: ScalableItemDelegate {
                id: delegate

                required property string itemText
                required property string iconSource
                required property var triggered

                width: listView.width

                text: itemText
                icon.source: iconSource

                Binding {
                    when: listView.iconOnly
                    delegate.display: AbstractButton.IconOnly
                    delegate.text: ""
                }

                highlighted: ListView.isCurrentItem

                focusPolicy: Qt.StrongFocus
                focus: true

                onClicked: {
                    if (!AppConfig.isPortraitLayout) {
                        root.close();
                    }
                    triggered();
                }
            }
        }

        VolumeController {
            id: volumeController

            volume: MainRadioPlayer.volume

            Layout.fillWidth: true
            Layout.fillHeight: true

            Layout.maximumHeight: implicitHeight
            Layout.minimumHeight: 150
            onVolumeChanged: {
                MainRadioPlayer.volume = volume;
            }
        }

        FocusScope {
            id: themeSwitchController

            visible: opacity > 0

            Layout.fillWidth: true
            implicitHeight: themeLayout.implicitHeight

            RowLayout {
                id: themeLayout

                width: parent.width

                Item {
                    Layout.horizontalStretchFactor: Utils.maxInteger
                    Layout.fillWidth: true
                }

                ScalableLabel {
                    text: qsTr("Dark")
                    Layout.fillWidth: true

                    elide: Text.ElideRight
                }

                Switch {
                    id: themeSwitch

                    Accessible.name: qsTr("Theme")
                    checked: !AppConfig.isDarkTheme
                    onCheckedChanged: {
                        AppSettings.theme = checked ? "Light" : "Dark";
                    }
                }

                ScalableLabel {
                    text: qsTr("Light")
                    Layout.fillWidth: true

                    elide: Text.ElideRight
                }

                Item {
                    Layout.horizontalStretchFactor: Utils.maxInteger
                    Layout.fillWidth: true
                }
            }
        }
    }
}
