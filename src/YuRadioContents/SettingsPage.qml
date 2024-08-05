pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import "radiobrowser.mjs" as RadioBrowser

import YuRadioContents
import network

Item {
    id: root

    required property NetworkManager networkManager

    focus: true

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.leftMargin: 15
        anchors.rightMargin: 5

        Label {
            text: qsTr("Servers")
            font.pointSize: 16
        }

        Rectangle {
            color: Material.foreground
            implicitWidth: parent.width * 2 / 3
            implicitHeight: 1
        }

        ListView {
            id: serversListView
            Layout.fillWidth: true
            implicitHeight: contentHeight
            boundsBehavior: Flickable.StopAtBounds

            ButtonGroup {
                id: buttonGroup
                onCheckedButtonChanged: {
                    if (root.networkManager.baseUrl != checkedButton.modelData) {
                        AppSettings.radioBrowserBaseUrl = checkedButton.modelData;
                        root.networkManager.baseUrl = checkedButton.modelData;
                    }
                }
            }
            delegate: ItemDelegate {
                required property string modelData

                implicitWidth: ListView.view.width * 2 / 3
                text: modelData
                checkable: true
                checked: modelData == root.networkManager.baseUrl
                down: checked
                autoExclusive: true
                ButtonGroup.group: buttonGroup
            }

            Component.onCompleted: {
                RadioBrowser.baseUrls().then(urls => {
                    model = [...new Set(urls)];
                });
            }
        }

        Label {
            text: qsTr("Could not fetch available servers")
            Material.foreground: Material.color(Material.Grey, Material.Shade500)
            opacity: 0.5
            visible: !serversListView.model || !serversListView.model.length
        }

        Label {
            text: qsTr("Initial Page")
            Layout.topMargin: 20
            font.pointSize: 16
        }

        ComboBox {
            implicitWidth: parent.width / 2
            model: [
                {
                    text: qsTr("Search"),
                    page: App.Page.Search
                },
                {
                    text: qsTr("Bookmarks"),
                    page: App.Page.Bookmark
                }
            ]
            textRole: "text"

            Component.onCompleted: {
                currentIndex = model.findIndex(x => x.page == AppSettings.initialPage);
            }
            onActivated: {
                AppSettings.initialPage = currentValue.page;
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
