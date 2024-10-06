import QtQuick

import YuRadioContents

ListViewSortHeader {
    id: root

    readonly property string orderByField: model.get(selectedIndex).field

    selectedIndex: 2
    width: ListView.view.width

    model: ListModel {
        ListElement {
            name: qsTr("track")
            field: "track_name"
        }
        ListElement {
            name: qsTr("station")
            field: "station_name"
        }
        ListElement {
            name: qsTr("start date")
            field: "datetime(started_at)"
        }
        ListElement {
            name: qsTr("end date")
            field: "datetime(ended_at)"
        }
    }
}
