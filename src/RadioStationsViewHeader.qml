pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

FocusScope {
    id: root

    height: 40
    width: ListView.view.width

    property string orderByField: "votes"
    property bool descending: true

    function _getOrderByField() {
        const field = buttonGroup.checkedButton?.text ?? "votes";
        if (field == "popularity") {
            return "clickcount";
        }
        return field;
    }

    ButtonGroup {
        id: buttonGroup
        onCheckedButtonChanged: {
            root.orderByField = root._getOrderByField();
        }
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            IconButton {
                id: orderByButton

                Layout.fillHeight: true
                Layout.leftMargin: 10
                transform: Scale {
                    id: orderByButtonScale
                    yScale: root.descending ? 1 : -1
                    origin.x: orderByButton.width / 2
                    origin.y: orderByButton.height / 2
                }

                icon.source: 'images/sort.svg'
                icon.sourceSize: Qt.size(height, height)

                icon.color: Material.primary

                onClicked: {
                    root.descending = !root.descending;
                }
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                orientation: Qt.Horizontal
                spacing: 2

                cacheBuffer: 1000000
                clip: true

                model: ["votes", "popularity", "bitrate", "name", "country", "state", "language", "tags"]

                delegate: OutlinedButton {
                    required property int index
                    required property string modelData

                    anchors.verticalCenter: parent.verticalCenter
                    height: ListView.view.height - 6

                    focusPolicy: Qt.NoFocus
                    autoExclusive: true
                    checkable: true
                    checked: modelData == "votes"

                    ButtonGroup.group: buttonGroup
                    text: modelData
                }
            }
        }
    }
}
