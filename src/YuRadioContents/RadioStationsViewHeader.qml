pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import YuRadioContents

FocusScope {
    id: root

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

    property string orderByField: "votes"
    property bool descending: true

    height: columnLayout.implicitHeight
    width: GridView.view.width

    ButtonGroup {
        id: buttonGroup
        onCheckedButtonChanged: {
            root.orderByField = internal.getOrderByField();
        }
    }

    ColumnLayout {
        id: columnLayout

        width: parent.width

        RowLayout {
            id: rowLayout

            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
                Layout.horizontalStretchFactor: 1
            }

            IconButton {
                id: orderByButton

                Layout.preferredWidth: Layout.preferredHeight + 8
                Layout.preferredHeight: listView.implicitHeight

                transform: Scale {
                    id: orderByButtonScale

                    yScale: root.descending ? 1 : -1
                    origin.x: orderByButton.width / 2
                    origin.y: orderByButton.height / 2
                }

                text: root.descending ? qsTr("Sort in ascending order") : qsTr("Sort in descending order")
                icon.source: 'images/sort.svg'
                icon.width: height
                icon.height: height

                icon.color: Material.primary

                onClicked: {
                    root.descending = !root.descending;
                }
            }

            ListView {
                id: listView

                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.maximumWidth: contentWidth
                Layout.horizontalStretchFactor: Utils.maxInteger

                implicitHeight: contentItem.childrenRect.height

                orientation: Qt.Horizontal
                spacing: 2

                cacheBuffer: 1000000
                clip: true
                focus: true

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

                    topInset: 5
                    bottomInset: 5

                    topPadding: 15
                    bottomPadding: 15
                    leftPadding: 14
                    rightPadding: 14

                    focusPolicy: Qt.StrongFocus
                    focus: true

                    autoExclusive: true
                    checkable: true
                    checked: index == 0
                    Accessible.name: qsTr("Sort by %1").arg(text)

                    ButtonGroup.group: buttonGroup
                    text: modelData.text
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.horizontalStretchFactor: 1
            }
        }
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
}
