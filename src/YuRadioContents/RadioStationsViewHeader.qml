import QtQuick

import YuRadioContents

ListViewSortHeader {
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

    readonly property string orderByField: internal.getOrderByField()

    width: GridView.view.width

    model: ListModel {
        ListElement {
            name: qsTr("votes")
            field: RadioStationsViewHeader.SortField.Votes
        }
        ListElement {
            name: qsTr("popularity")
            field: RadioStationsViewHeader.SortField.Popularity
        }
        ListElement {
            name: qsTr("bitrate")
            field: RadioStationsViewHeader.SortField.Bitrate
        }
        ListElement {
            name: qsTr("name")
            field: RadioStationsViewHeader.SortField.Name
        }
        ListElement {
            name: qsTr("country")
            field: RadioStationsViewHeader.SortField.Country
        }
        ListElement {
            name: qsTr("state")
            field: RadioStationsViewHeader.SortField.State
        }
        ListElement {
            name: qsTr("language")
            field: RadioStationsViewHeader.SortField.Language
        }
        ListElement {
            name: qsTr("tags")
            field: RadioStationsViewHeader.SortField.Tags
        }
    }

    QtObject {
        id: internal

        function getOrderByField() {
            const field = root.model.get(root.selectedIndex).field ?? RadioStationsViewHeader.SortField.Votes;
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
