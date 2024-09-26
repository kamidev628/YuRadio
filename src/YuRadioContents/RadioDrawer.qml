pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls
import QtQuick.Layouts

import YuRadioContents

Drawer {
    id: root

    property bool isDesktopLayout: true

    signal showBookmarksRequested
    signal showSearchRequested
    signal showSettingsRequested
    signal showAboutRequested

    width: Math.min(Math.min(parent.width, parent.height) / 3 * 2, implicitWidth)
    height: parent.height

    Material.roundedScale: Material.NotRounded

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
            Layout.fillHeight: true
            Layout.fillWidth: true

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
                required property string itemText
                required property string iconSource
                required property var triggered

                width: parent.width

                text: itemText
                icon.source: iconSource
                highlighted: ListView.isCurrentItem

                focusPolicy: Qt.StrongFocus
                focus: true

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

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

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
