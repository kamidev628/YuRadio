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

    enum SortField {
        Votes,
        Popularity,
        Bitrate,
        Name,
        Country,
        State,
        Language,
        Tags
    }

    QtObject {
        id: internal

        function getOrderByField() {
            const field = buttonGroup.checkedButton?.modelData.field ?? RadioStationsViewHeader.SortField.Votes;
            switch (field) {
            case RadioStationsViewHeader.SortField.Votes:
                return "votes";
            case RadioStationsViewHeader.SortField.Popularity:
                return "clickcount";
            case RadioStationsViewHeader.SortField.Bitrate:
                return "bitrate";
            case RadioStationsViewHeader.SortField.Name:
                return "name";
            case RadioStationsViewHeader.SortField.Country:
                return "country";
            case RadioStationsViewHeader.SortField.State:
                return "state";
            case RadioStationsViewHeader.SortField.Language:
                return "language";
            case RadioStationsViewHeader.SortField.Tags:
                return "tags";
            }
            return "votes";
        }
    }

    ButtonGroup {
        id: buttonGroup
        onCheckedButtonChanged: {
            root.orderByField = internal.getOrderByField();
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

                model: [
                    {
                        text: qsTr("votes"),
                        field: RadioStationsViewHeader.SortField.Votes
                    },
                    {
                        text: qsTr("popularity"),
                        field: RadioStationsViewHeader.SortField.Popularity
                    },
                    {
                        text: qsTr("bitrate"),
                        field: RadioStationsViewHeader.SortField.Bitrate
                    },
                    {
                        text: qsTr("name"),
                        field: RadioStationsViewHeader.SortField.Name
                    },
                    {
                        text: qsTr("country"),
                        field: RadioStationsViewHeader.SortField.Country
                    },
                    {
                        text: qsTr("state"),
                        field: RadioStationsViewHeader.SortField.State
                    },
                    {
                        text: qsTr("language"),
                        field: RadioStationsViewHeader.SortField.Language
                    },
                    {
                        text: qsTr("tags"),
                        field: RadioStationsViewHeader.SortField.Tags
                    }
                ]

                delegate: OutlinedButton {
                    required property int index
                    required property var modelData

                    anchors.verticalCenter: parent.verticalCenter
                    height: ListView.view.height - 6

                    focusPolicy: Qt.NoFocus
                    autoExclusive: true
                    checkable: true
                    checked: index == 0

                    ButtonGroup.group: buttonGroup
                    text: modelData.text
                }
            }
        }
    }
}
