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

    property string viewType: AppSettings.historyPageView
    property bool isTableViewType: viewType === "table"

    readonly property string queryFilters: filters.length > 0 ? "WHERE " + filters.join(" AND ") : ""

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

            maximumWidth: Math.min(parent.width * 6 / 9, AppConfig.searchBarMaximumWidth)

            implicitWidth: height
            searchIcon.color: Material.color(Material.Grey, Material.Shade100)

            Layout.fillHeight: true

            searchInput.onAccepted: {
                root.acceptedInputText = searchInput.text;
            }
        }

        Item {
            visible: searchBar.isDesktopLayout
            Layout.fillWidth: true
        }

        IconButton {
            id: changeViewButton

            Layout.fillHeight: true
            implicitWidth: height

            display: AbstractButton.IconOnly

            icon.source: root.isTableViewType ? 'images/list.svg' : 'images/table.svg'
            icon.color: Material.color(Material.Grey, Material.Shade100)

            text: root.isTableViewType ? qsTr("Display as list") : qsTr("Display as table")

            onClicked: {
                if (root.isTableViewType) {
                    AppSettings.historyPageView = "list";
                } else {
                    AppSettings.historyPageView = "table";
                }
            }
        }

        ToolButton {
            id: filterButton

            Accessible.name: qsTr("Search Filters")
            icon.source: 'images/filter.svg'
            icon.color: Material.color(Material.Grey, Material.Shade100)

            onClicked: {
                filterButton.forceActiveFocus();
                root.openSearchFilterDialog();
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
        asynchronous: true

        sourceComponent: HistorySearchFilterDialog {
            id: searchFilterDialog

            implicitWidth: Math.min(Overlay.overlay.width * 5 / 6, 500)
            implicitHeight: Overlay.overlay.height * 5 / 6

            anchors.centerIn: Overlay.overlay
        }
        onLoaded: root.searchFilterDialog.open()
    }

    Loader {
        id: mainContentsLoader

        anchors.fill: parent

        asynchronous: true

        sourceComponent: root.isTableViewType ? tableViewComponent : listViewComponent
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
