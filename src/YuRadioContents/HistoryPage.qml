pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import YuRadioContents

Item {
    id: root

    property string acceptedInputText
    readonly property HistorySearchFilterDialog searchFilterDialog: searchFilterDialogLoader.item as HistorySearchFilterDialog

    readonly property string queryFilters: filters.length > 0 ? "WHERE " + filters.join(" AND ") : ""
    onQueryFiltersChanged: {
        console.log("queryFilters", queryFilters);
    }

    property string searchByField: "station_name"
    property date startDate
    property date endDate

    readonly property list<string> filters: [
        /* Input      */ acceptedInputText.length > 0 ? `${searchByField} LIKE '%${Utils.mysql_real_escape_string(root.acceptedInputText).split("").join("%")}%' ESCAPE '\\'` : "",
        /* Start Date */ Utils.isDateValid(startDate) ? `started_at > '${Utils.dateToISOString(startDate)}'` : "",
        /* End Date   */ Utils.isDateValid(endDate) ? `ended_at < '${Utils.dateToISOString(endDate)}'` : ""].filter(x => x)

    property Component headerContent: RowLayout {
        id: headerLayout

        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
        }

        SearchBar {
            id: searchBar

            availableWidth: Math.min(parent.width * 5 / 9, 300)

            implicitWidth: height
            searchIcon.color: Material.color(Material.Grey, Material.Shade100)

            Layout.fillHeight: true

            searchInput.onAccepted: {
                root.acceptedInputText = searchInput.text;
            }
        }

        ToolButton {
            id: filterIcon

            Accessible.name: qsTr("Search Filters")
            icon.source: 'images/filter.svg'
            icon.color: Material.color(Material.Grey, Material.Shade100)

            onClicked: {
                filterIcon.forceActiveFocus();
                root.openSearchFilterDialog();
            }
        }

        CheckBox {
            text: "switch"
            onCheckedChanged: {
                if (checked) {
                    AppSettings.historyPageView = "table";
                } else {
                    AppSettings.historyPageView = "list";
                }
            }
        }

        Shortcut {
            sequences: [StandardKey.Find, "Ctrl+E"]
            onActivated: {
                searchBar.activate();
            }
        }
    }

    function openSearchFilterDialog(): void {
        if (searchFilterDialog) {
            searchFilterDialog.open();
        } else {
            searchFilterDialogLoader.active = true;
        }
    }

    Loader {
        id: searchFilterDialogLoader

        anchors.fill: parent

        active: false

        sourceComponent: HistorySearchFilterDialog {
            id: searchFilterDialog

            implicitWidth: Math.min(Overlay.overlay.width * 3 / 4, 500)
            implicitHeight: Overlay.overlay.height * 3 / 4

            anchors.centerIn: Overlay.overlay
        }
        onLoaded: root.searchFilterDialog.open()
    }

    Loader {
        id: mainContentsLoader

        anchors.fill: parent

        sourceComponent: AppSettings.historyPageView === "table" ? tableViewComponent : listViewComponent
    }

    Timer {
        id: refreshModelTimer

        interval: 500
        running: root.visible && AppStorage.streamTitleHistoryDirty
        repeat: false

        onTriggered: {
            AppStorage.streamTitleHistoryDirty = false;
            mainContentsLoader.item?.refreshModel();
        }
    }

    Connections {
        target: root.searchFilterDialog

        function onFiltersChanged(searchByField: string, startDate: date, endDate: date) {
            root.searchByField = searchByField;
            root.startDate = startDate;
            root.endDate = endDate;
        }
    }

    Component {
        id: listViewComponent

        HistoryListView {
            queryFilters: root.queryFilters
        }
    }

    Component {
        id: tableViewComponent

        HistoryTableView {
            queryFilters: root.queryFilters
        }
    }
}
