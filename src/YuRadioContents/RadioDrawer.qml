pragma ComponentBehavior: Bound

import Main
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls
import QtQuick.Layouts

Drawer {
    id: root

    property bool isDesktopLayout: true

    width: Math.min(Math.min(parent.width, parent.height) / 3 * 2, implicitWidth)
    height: parent.height

    Material.roundedScale: Material.NotRounded

    signal showBookmarksRequested
    signal showSearchRequested
    signal showSettingsRequested
    signal showAboutRequested

    ColumnLayout {
        id: columnLayout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Image {
            id: profileImage

            Layout.preferredWidth: parent.width * 2 / 5
            Layout.preferredHeight: parent.width * 2 / 5
            Layout.alignment: Qt.AlignHCenter

            source: "images/shortwave.svg"
            asynchronous: true
            smooth: true
        }

        ListView {
            focus: true
            currentIndex: -1

            Layout.fillHeight: true
            Layout.fillWidth: true
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

            delegate: ItemDelegate {
                required property string itemText
                required property string iconSource
                required property var triggered

                width: parent.width
                text: itemText
                icon.source: iconSource
                highlighted: ListView.isCurrentItem
                onClicked: {
                    if (!root.isDesktopLayout) {
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
            onVolumeChanged: {
                MainRadioPlayer.volume = volume;
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter

            Text {
                text: qsTr("Dark")
                anchors.verticalCenter: parent.verticalCenter
                color: root.Material.primaryTextColor
            }
            Switch {
                id: themeSwitch
                checked: !AppConfig.isDarkTheme
                onClicked: {
                    AppSettings.theme = Qt.binding(() => {
                        return checked ? "Light" : "Dark";
                    });
                }
            }
            Text {
                text: qsTr("Light")
                anchors.verticalCenter: parent.verticalCenter
                color: root.Material.primaryTextColor
            }
        }
    }
}
