pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import "radiobrowser.mjs" as RadioBrowser

import YuRadioContents
import network

Item {
    id: root

    focus: true

    property alias bottomDrawer: bottomBarDrawer
    required property RadioDrawer drawer
    required property NetworkManager networkManager

    property var radioModelFilters: ({
            reverse: true
        })

    function openSearchFilterDialog() {
        /* TODO: underlying drag handler steals drag events from
         * search-filter-dialog
         */
        root.bottomDrawer.close();
        if (searchFilterDialogLoader.active) {
            searchFilterDialogLoader.item.open();
        } else {
            searchFilterDialogLoader.active = true;
        }
    }

    function radioModelAddFilter(key, value) {
        if (Utils.isEmpty(value)) {
            delete root.radioModelFilters[key];
        } else {
            root.radioModelFilters[key] = value;
        }
    }

    function radioModelReset() {
        radioPagination.offset = 0;
        root.radioModelFiltersChanged();
        radioModel.reset();
        radioListView.flick(0, 1);
    }

    property Component headerContent: RowLayout {
        anchors.fill: parent

        Item {
            Layout.fillWidth: true
        }

        SearchBar {
            id: searchBar

            availableWidth: parent.width * 2 / 5

            implicitWidth: height

            Layout.fillHeight: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8

            searchInput.onAccepted: {
                root.radioModelAddFilter("name", searchInput.text);
                root.radioModelReset();
            }
        }

        IconButton {
            id: filterIcon
            icon.source: 'images/filter.svg'
            icon.sourceSize: searchBar.searchIcon.sourceSize

            icon.color: Material.color(Material.Grey, Material.Shade100)

            Layout.rightMargin: 10
            onClicked: {
                filterIcon.forceActiveFocus();
                root.openSearchFilterDialog();
            }
        }
    }

    Loader {
        id: searchFilterDialogLoader

        active: false

        anchors.fill: parent

        sourceComponent: RadioStationSearchFilterDialog {
            id: searchFilterDialog
            implicitWidth: parent.width * 3 / 4
            implicitHeight: parent.height * 3 / 4
            anchors.centerIn: parent
            networkManager: root.networkManager
            onAccepted: {
                root.radioModelAddFilter("country", searchFilterDialog.selectedCountry);
                root.radioModelAddFilter("state", searchFilterDialog.selectedState);
                root.radioModelAddFilter("language", searchFilterDialog.selectedLanguage);
                root.radioModelAddFilter("tagList", searchFilterDialog.selectedTags().join(','));
                root.radioModelReset();
            }
        }
        onLoaded: item.open()
    }

    JsonRestListModel {
        id: radioModel

        restManager: root.networkManager
        pagination: LimitPagination {
            id: radioPagination
            limit: 20
            offset: 0
            totalCount: 50
        }

        path: "/json/stations/search"
        filters: root.radioModelFilters

        orderByQuery: "order"
        orderBy: "votes"

        function loadPageHandler() {
            loadPage();
        }

        preprocessItem: function (item) {
            if (!item.url_resolved && !item.url) {
                return undefined;
            }
            item.name = item.name.trim();
            item.tags = item.tags.trim().split(',').join(', ');
            item.language = item.language.trim().split(',').join(', ');
            if (!item.url_resolved) {
                item.url_resolved = item.url;
            }
            return item;
        }

        onStatusChanged: {
            if (status == JsonRestListModel.Ready) {
                radioPagination.nextPage();
                if (radioModel.rowCount() % radioPagination.offset !== 0) {
                    radioPagination.totalCount = radioModel.rowCount();
                } else {
                    radioPagination.totalCount = 60;
                }
            }
        }

        fetchMoreHandler: loadPageHandler
    }

    component HighlightBar: Rectangle {
        width: ListView.view.currentItem?.width ?? 0
        height: ListView.view.currentItem?.height ?? 0

        color: "lightsteelblue"
        y: ListView.view.currentItem?.y ?? 0
        opacity: 0.6
        Behavior on y {
            SpringAnimation {
                spring: 4
                damping: 0.5
            }
        }
    }

    component FooterBar: BusyIndicator {
        width: ListView.view.width
        height: visible ? 50 : 0
        visible: radioModel.status == JsonRestListModel.Loading
    }

    ListView {
        id: radioListView

        displayMarginEnd: bottomBarDrawer.height
        currentIndex: -1

        clip: true
        focus: true

        boundsMovement: Flickable.StopAtBounds
        boundsBehavior: Flickable.DragOverBounds

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: bottomBarDrawer.top
        }

        header: RadioStationsViewHeader {
            id: radioListViewHeader

            function orderChangedHandler() {
                radioModel.orderBy = orderByField;
                root.radioModelAddFilter("reverse", descending);
                root.radioModelReset();
            }

            onDescendingChanged: orderChangedHandler()
            onOrderByFieldChanged: orderChangedHandler()
        }
        footer: FooterBar {}
        highlight: HighlightBar {}

        highlightFollowsCurrentItem: false
        model: radioModel
        delegate: RadioStationDelegate {
            id: delegate

            focus: true
            focusPolicy: Qt.StrongFocus
            networkManager: root.networkManager

            onCurrentStationChanged: {
                if (currentStation) {
                    Qt.callLater(() => {
                        radioListView.currentIndex = Qt.binding(() => MainRadioPlayer.currentItem?.stationuuid == delegate.stationuuid ? index : -1);
                    });
                }
            }

            onClicked: {
                if (ListView.view.currentIndex == delegate.index) {
                    MainRadioPlayer.toggle();
                } else {
                    RadioBrowser.click(root.networkManager.baseUrl, stationuuid);
                    radioListView.currentIndex = delegate.index;
                    MainRadioPlayer.currentItem = Object.assign({}, radioListView.model.get(delegate.index));
                    Qt.callLater(MainRadioPlayer.play);
                }
            }
        }

        Timer {
            id: apiTimeoutTimer
            interval: 3000
        }

        Timer {
            id: refreshTimer
            interval: 1000
        }

        PullToRefreshHandler {
            id: pullToRefreshHandler
            enabled: isProcessing && !apiTimeoutTimer.running && radioListView.verticalOvershoot <= 0
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
        listView: radioListView
    }

    Connections {
        target: root.drawer
        function onOpened() {
            bottomBarDrawer.close();
        }
    }

    Connections {
        target: root.networkManager
        function onBaseUrlChanged() {
            root.radioModelReset();
        }
    }
}
