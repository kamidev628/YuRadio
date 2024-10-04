pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import YuRadioContents
import Main

Item {
    id: root

    property string acceptedInputText
    readonly property HistorySearchFilterDialog searchFilterDialog: searchFilterDialogLoader.item as HistorySearchFilterDialog
    readonly property string queryFilters: acceptedInputText.length > 0 ? `WHERE track_name LIKE '%${Utils.mysql_real_escape_string(root.acceptedInputText).split("").join("%")}%' ESCAPE '\\'` : ""

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
}
