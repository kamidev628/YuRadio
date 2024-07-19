pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import QtMultimedia

import "radiobrowser.mjs" as RadioBrowser

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

    property ToolBar header: ToolBar {
        id: header

        RowLayout {
            anchors.fill: parent

            ToolButton {
                id: menuButton
                icon.source: "images/menu.svg"
                Material.foreground: Material.color(Material.Grey, Material.Shade100)
                onClicked: {
                    root.mainDrawer.open();
                    bottomBarDrawer.close();
                }
            }

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
        width: ListView.view.currentItem.width
        height: ListView.view.currentItem.height

        color: "lightsteelblue"
        y: ListView.view.currentItem.y
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
                radioPlayer.currentItem = model.get(currentIndex);
                Qt.callLater(radioPlayer.play);
            }
        }

        onCountChanged:
        //flick(0, 1);
        {}

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
                    radioPlayer.toggle();
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

        RadioBottomBar {
            id: bottomBar
            player: radioPlayer

            anchors.fill: parent

            bottomBarDragHandler: bottomBarDrawer.dragHandler
            minimumHeight: bottomBarDrawer.minimumHeight
            maximumHeight: bottomBarDrawer.maximumHeight

            Binding {
                when: radioPlayer.currentItem !== undefined
                bottomBar.stationName: radioPlayer.currentItem.name
                bottomBar.stationTags: radioPlayer.currentItem.tags
                bottomBar.stationUrl: radioPlayer.currentItem.url_resolved
                bottomBar.stationIcon: radioPlayer.currentItem.favicon
                bottomBar.stationHomepage: radioPlayer.currentItem.homepage
                bottomBar.stationCountry: radioPlayer.currentItem.country
                bottomBar.stationLanguage: radioPlayer.currentItem.language
            }
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

        icon.source: radioPlayer.playing ? "images/pause.svg" : "images/play.svg"
        icon.width: width / 2
        icon.height: height / 2

        opacity: bottomBarDrawer.progress

        visible: !bottomBar.playerButton.visible
        onClicked: {
            radioPlayer.toggle();
        }

        width: 60
        height: 60
    }

    RadioPlayer {
        id: radioPlayer

        property var currentItem: undefined

        source: currentItem ? currentItem.url_resolved : ""
        icecastHint: currentItem ? /MP3|mp3|AAC|aac/.test(currentItem.codec) : false
        audioOutput: AudioOutput {
            volume: 0.3
        }
    }
}
