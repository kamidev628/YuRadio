pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Effects

import "radiobrowser.mjs" as RadioBrowser

import YuRadioContents
import network
import Main

Item {
    id: root

    focus: true

    property alias bottomDrawer: bottomBarDrawer
    required property RadioDrawer mainDrawer

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
        radioListView.currentIndex = -1;
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
            networkManager: apiManager
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

    NetworkManager {
        id: apiManager

        Component.onCompleted: {
            const radioBrowser = new RadioBrowser.RadioBrowser;
            radioBrowser.baseUrlRandom().then(url => {
                console.log("RadioBrowser BaseUrl:", url);
                baseUrl = url;
            });
        }

        onBaseUrlChanged: {
            root.radioModelReset();
        }
    }

    JsonRestListModel {
        id: radioModel

        restManager: apiManager
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

        onCurrentIndexChanged: {
            if (currentIndex != -1) {
                MainRadioPlayer.currentItem = model.get(currentIndex);
                Qt.callLater(MainRadioPlayer.play);
            }
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

            onClicked: {
                if (ListView.view.currentIndex == delegate.index) {
                    MainRadioPlayer.toggle();
                } else {
                    const radioBrowser = new RadioBrowser.RadioBrowser;
                    radioBrowser.click(apiManager.baseUrl, stationuuid);
                    ListView.view.currentIndex = index;
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

    RadioBottomBarDrawer {
        id: bottomBarDrawer

        maximumHeight: parent.height * 2 / 3
        minimumHeight: Math.max(parent.height / 12, bottomBar.implicitHeight)

        ShaderEffectSource {
            id: effectSource
            anchors.fill: parent
            sourceItem: radioListView
            sourceRect: Qt.rect(0, radioListView.height, bottomBarDrawer.width, bottomBarDrawer.height)
            visible: false
        }

        background: MultiEffect {
            source: effectSource
            autoPaddingEnabled: false
            blurEnabled: true
            blurMax: 64
            blur: 0.95
            saturation: -0.3
        }

        RadioBottomBar {
            id: bottomBar

            anchors.fill: parent

            bottomBarDragHandler: bottomBarDrawer.dragHandler
            minimumHeight: bottomBarDrawer.minimumHeight
            maximumHeight: bottomBarDrawer.maximumHeight
        }

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
    }

    RoundButton {
        anchors {
            bottom: bottomBarDrawer.top
            right: parent.right
            rightMargin: 8
            bottomMargin: 8
        }

        icon.source: MainRadioPlayer.playing ? "images/pause.svg" : "images/play.svg"
        icon.width: width / 2
        icon.height: height / 2

        opacity: bottomBarDrawer.progress

        visible: !bottomBar.playerButton.visible
        onClicked: {
            MainRadioPlayer.toggle();
        }

        width: 60
        height: 60
    }

    Connections {
        target: root.mainDrawer
        function onOpened() {
            bottomBarDrawer.close();
        }
    }
}
