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

    property bool morphBackground: !radioGridView.atYBeginning

    required property bool isDesktopLayout
    required property RadioDrawer drawer
    required property NetworkManager networkManager
    required property MusicInfoModel musicInfoModel
    required property RadioStationInfoPanel stationInfoPanel

    readonly property RadioStationSearchFilterDialog searchFilterDialog: searchFilterDialogLoader.item as RadioStationSearchFilterDialog

    property Component headerContent: RowLayout {
        id: headerLayout

        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
        }

        Item {
            Layout.minimumWidth: 0
            Layout.maximumWidth: refreshButton.width
            Layout.fillWidth: true
        }

        SearchBar {
            id: searchBar

            maximumWidth: Math.min(parent.width * 6 / 9, AppConfig.searchBarMaximumWidth)

            implicitWidth: height

            Layout.fillHeight: true

            searchInput.onAccepted: {
                nameFilter.value = searchInput.text;
                root.radioModelReset();
            }
        }

        Item {
            visible: searchBar.isDesktopLayout
            Layout.fillWidth: true
        }

        ToolButton {
            id: refreshButton

            text: qsTr("Refresh")
            icon.source: "images/refresh.svg"
            icon.color: enabled ? AppColors.toolButtonColor : root.Material.background.darker(AppConfig.isDarkTheme ? 0.7 : 1.3)
            display: AbstractButton.IconOnly

            enabled: !pullToRefreshHandler.isProcessing && !apiTimeoutTimer.running
            onClicked: {
                root.radioModelReset();
            }
        }

        ToolButton {
            id: filterIcon

            text: qsTr("Search Filters")
            icon.source: 'images/filter.svg'
            icon.color: AppColors.toolButtonColor
            display: AbstractButton.IconOnly

            onClicked: {
                filterIcon.forceActiveFocus();
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

            implicitWidth: Math.min(Overlay.overlay.width * 5 / 6, 500)
            implicitHeight: Overlay.overlay.height * 6 / 7

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
        onLoaded: root.searchFilterDialog.open()
    }

    Timer {
        id: loadPageTimer

        function loadPage() {
            radioModel.loadPage();
            if (!apiTimeoutTimer.running && apiTimeoutTimer.shouldRun) {
                apiTimeoutTimer.start();
            }
        }

        interval: apiTimeoutTimer.interval
        onTriggered: loadPage()
    }

    RadioStationModel {
        id: radioModel

        function loadPageHandler() {
            if (apiTimeoutTimer.running) {
                loadPageTimer.start();
            } else {
                loadPageTimer.loadPage();
            }
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

        onStatusChanged: {
            if (status == RadioStationModel.Ready) {
                radioPagination.nextPage();
            }
        }

        fetchMoreHandler: loadPageHandler
    }

    component FooterBar: BusyIndicator {
        width: GridView.view.width
        height: visible ? 50 : 0
        visible: radioModel.status === RadioStationModel.Loading
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
        stationAtIndex: index => radioModel.get(index)

        footer: FooterBar {}
        model: radioModel

        Timer {
            id: apiTimeoutTimer

            property bool shouldRun: true

            interval: 1000
        }

        Timer {
            id: refreshTimer
            interval: 2000
        }

        PullToRefreshHandler {
            id: pullToRefreshHandler

            enabled: isProcessing && !apiTimeoutTimer.running && radioGridView.verticalOvershoot <= 0
            refreshCondition: refreshTimer.running

            onPullDownRelease: {
                refreshTimer.start();
                apiTimeoutTimer.shouldRun = false;
                root.radioModelReset();
            }

            onRefreshed: {
                apiTimeoutTimer.shouldRun = true;
            }
        }

        ScalableLabel {
            width: radioGridView.width
            height: radioGridView.height

            visible: radioModel.status !== RadioStationModel.Loading && radioGridView.count === 0

            text: radioModel.status === RadioStationModel.Error ? qsTr("Network failure") : qsTr("No results available")
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
            fontPointSize: 20
            opacity: 0.6
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
        stackView: root.StackView.view as StackView
        musicInfoModel: root.musicInfoModel
    }

    Shortcut {
        sequences: [StandardKey.Refresh, "Ctrl+R"]
        onActivated: {
            root.radioModelReset();
        }
    }

    Connections {
        target: root.networkManager

        function onBaseUrlChanged() {
            root.radioModelReset();
        }
    }
}
