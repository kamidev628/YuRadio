import QtQuick

import YuRadioContents

ListViewSortHeader {
    id: root

    readonly property string orderByField: model.get(selectedIndex).field

    width: GridView.view.width

    model: ListModel {
        ListElement {
            name: qsTr("Votes")
            field: "votes"
        }
        ListElement {
            name: qsTr("Popularity")
            field: "clickcount"
        }
        ListElement {
            name: qsTr("Bitrate")
            field: "bitrate"
        }
        ListElement {
            name: qsTr("Name")
            field: "name"
        }
        ListElement {
            name: qsTr("Country")
            field: "country"
        }
        ListElement {
            name: qsTr("State")
            field: "state"
        }
        ListElement {
            name: qsTr("Language")
            field: "language"
        }
        ListElement {
            name: qsTr("Tags")
            field: "tags"
        }
    }
}
