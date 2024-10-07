import QtQuick

import YuRadioContents

ListViewSortHeader {
    id: root

    readonly property string orderByField: model.get(selectedIndex).field

    selectedIndex: 2
    width: ListView.view.width

    model: ListModel {
        ListElement {
            name: qsTr("Track")
            field: "track_name"
        }
        ListElement {
            name: qsTr("Station")
            field: "station_name"
        }
        ListElement {
            name: qsTr("Start date")
            field: "datetime(started_at)"
        }
        ListElement {
            name: qsTr("End date")
            field: "datetime(ended_at)"
        }
    }
}
