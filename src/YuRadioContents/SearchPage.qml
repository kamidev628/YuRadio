pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import YuRadioContents
import network
import Main

Item {
    id: root

    required property bool isDesktopLayout
    required property RadioDrawer drawer
    required property NetworkManager networkManager
    required property MusicInfoModel musicInfoModel

    readonly property RadioStationSearchFilterDialog searchFilterDialog: searchFilterDialogLoader.item as RadioStationSearchFilterDialog

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
                nameFilter.value = searchInput.text;
                root.radioModelReset();
            }
        }

        ToolButton {
            id: refreshButton

            icon.source: "images/refresh.svg"
            icon.color: enabled ? Material.color(Material.Grey, Material.Shade100) : ApplicationWindow.header.Material.background.darker(1.2)

            enabled: !pullToRefreshHandler.isProcessing && !apiTimeoutTimer.running
            onClicked: {
                root.radioModelReset();
                apiTimeoutTimer.start();
            }
        }

        ToolButton {
            id: filterIcon

            icon.source: 'images/filter.svg'
            icon.color: Material.color(Material.Grey, Material.Shade100)

            onClicked: {
                filterIcon.forceActiveFocus();
                root.openSearchFilterDialog();
            }
        }
    }

    function openSearchFilterDialog(): void {
        if (searchFilterDialogLoader.active) {
            searchFilterDialogLoader.item.open();
        } else {
            searchFilterDialogLoader.active = true;
        }
    }

    function radioModelReset(): void {
        radioPagination.offset = 0;
        radioModel.reset();
        radioGridView.currentIndex = -1;
    }

    focus: true

    Loader {
        id: searchFilterDialogLoader

        anchors.fill: parent

        active: false

        sourceComponent: RadioStationSearchFilterDialog {
            id: searchFilterDialog

            implicitWidth: Math.min(Overlay.overlay.width * 3 / 4, 500)
            implicitHeight: Overlay.overlay.height * 3 / 4

            anchors.centerIn: Overlay.overlay

            networkManager: root.networkManager
            onFiltersChanged: (country, state, language, tags) => {
                countryFilter.value = country;
                stateFilter.value = state;
                languageFilter.value = language;
                tagListFilter.value = tags.join(',');
                root.radioModelReset();
            }
        }
        onLoaded: item.open()
    }

    JsonRestListModel {
        id: radioModel

        function loadPageHandler() {
            loadPage();
        }

        restManager: root.networkManager
        pagination: LimitPagination {
            id: radioPagination
            limit: 40
            offset: 0
            totalCount: (radioModel.count + 1) % (radioPagination.offset + 1) == 0 ? 500 : radioModel.count
        }

        path: "/json/stations/search"
        filters: [
            RestListModelSortFilter {
                id: radioModelOrderBy
                key: "order"
                value: "votes"
            },
            RestListModelSortFilter {
                id: reverseOrderBy
                key: "reverse"
                value: true
            },
            RestListModelSortFilter {
                id: nameFilter
                key: "name"
            },
            RestListModelSortFilter {
                id: countryFilter
                key: "country"
            },
            RestListModelSortFilter {
                id: stateFilter
                key: "state"
            },
            RestListModelSortFilter {
                id: languageFilter
                key: "language"
            },
            RestListModelSortFilter {
                id: tagListFilter
                key: "tagList"
            }
        ]

        preprocessItem: item => {
            if (!item.url_resolved && !item.url) {
                return undefined;
            }
            item.name = item.name.trim();
            item.tags = item.tags.trim().split(',').join(', ');
            item.language = item.language.trim().split(',').join(', ');
            if (item.bitrate > 1411) {
                item.bitrate /= 1000;
            }
            if (!item.url_resolved) {
                item.url_resolved = item.url;
            }
            return item;
        }

        onStatusChanged: {
            if (status == JsonRestListModel.Ready) {
                radioPagination.nextPage();
            }
        }

        fetchMoreHandler: loadPageHandler
    }

    component FooterBar: BusyIndicator {
        width: GridView.view.width
        height: visible ? 50 : 0
        visible: radioModel.status == JsonRestListModel.Loading
    }

    RadioStationView {
        id: radioGridView

        bottomBar: bottomBarDrawer
        networkManager: root.networkManager

        header: RadioStationsViewHeader {
            id: radioListViewHeader

            function orderChangedHandler() {
                radioModelOrderBy.value = orderByField;
                reverseOrderBy.value = descending;
                root.radioModelReset();
            }

            onDescendingChanged: orderChangedHandler()
            onOrderByFieldChanged: orderChangedHandler()
        }

        footer: FooterBar {}
        model: radioModel

        Timer {
            id: apiTimeoutTimer
            interval: 4500
        }

        Timer {
            id: refreshTimer
            interval: 1500
        }

        PullToRefreshHandler {
            id: pullToRefreshHandler

            enabled: isProcessing && !apiTimeoutTimer.running && radioGridView.verticalOvershoot <= 0
            refreshCondition: refreshTimer.running

            onPullDownRelease: {
                refreshTimer.start();
                root.radioModelReset();
            }

            onRefreshed: {
                apiTimeoutTimer.start();
            }
        }
    }

    RadioBottomBar {
        id: bottomBarDrawer

        interactive: {
            if (!root.searchFilterDialog) {
                return true;
            }
            if (root.searchFilterDialog.opened || (root.drawer.opened && !root.isDesktopLayout)) {
                return false;
            }
            return true;
        }

        gridView: radioGridView
        stackView: root.StackView.view
        musicInfoModel: root.musicInfoModel
    }

    Connections {
        target: root.networkManager

        function onBaseUrlChanged() {
            root.radioModelReset();
        }
    }
}
