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
            text: "Servers"
            font.pointSize: 16
        }

        Rectangle {
            implicitWidth: parent.width * 2 / 3
            implicitHeight: 1
        }

        ListView {
            id: serversListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            boundsBehavior: Flickable.StopAtBounds

            ButtonGroup {
                id: buttonGroup
                onCheckedButtonChanged: {
                  if (root.networkManager.baseUrl != checkedButton.modelData) {
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

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
