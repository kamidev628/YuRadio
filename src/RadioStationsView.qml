import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import QtMultimedia

import Main

Item {
    id: root

    property alias bottomDrawer: bottomBarDrawer
    required property RadioDrawer mainDrawer

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
                    radioModel.path = "/json/stations" + (searchInput.text ? `/byname/${searchInput.text}` : "");
                }
            }

            IconImage {
                id: filterIcon
                source: 'images/filter.svg'
                sourceSize: searchBar.searchIcon.sourceSize

                color: Material.color(Material.Grey, Material.Shade100)

                Layout.rightMargin: 10

                MouseArea {
                    anchors.fill: parent
                    onClicked:
                    //searchInput.forceActiveFocus();
                    {}
                }
            }
        }
    }

    LimitPagination {
        id: limitOffsetPagination
        limit: 10
        offset: 0
        totalCount: 50
    }

    NetworkManager {
        id: apiManager
        baseUrl: "http://de1.api.radio-browser.info"
    }

    JsonRestListModel {
        id: radioModel

        restManager: apiManager
        pagination: limitOffsetPagination
        path: "/json/stations"

        orderByQuery: "order"
        orderBy: "votes"

        function loadPageHandler() {
            loadPage();
            limitOffsetPagination.nextPage();
        }

        preprocessItem: function (item) {
            item.name = item.name.trim();
            item.tags = item.tags.trim().split(',').join(', ');
            item.language = item.language.trim().split(',').join(', ');

            const iconExtension = item.favicon.split('.').pop()
            if (iconExtension == 'ico') {
              item.favicon = undefined
            }
            return item;
        }

        onPathChanged: {
            limitOffsetPagination.offset = 0;
            radioListView.currentIndex = -1;
            reset();
        }

        fetchMoreHandler: loadPageHandler
    }

        component HighlightBar : Rectangle {
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

    ListView {
        id: radioListView

        cacheBuffer: 300
        currentIndex: -1
        clip: true
        focus: true

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: bottomBarDrawer.top
        }

        onCurrentItemChanged: {
            if (currentIndex != -1) {
                Qt.callLater(radioPlayer.playRadio);
            }
        }
        onCurrentIndexChanged: {
            if (currentIndex != -1) {
                radioPlayer.currentItem = model.get(currentIndex);
            }
        }

        highlight: HighlightBar {}
        highlightFollowsCurrentItem: false
        model: radioModel
        delegate: RadioStationDelegate {
          id: delegate
          onClicked: {
            if (radioListView.currentIndex == delegate.index) {
              radioPlayer.toggleRadio()
            } else {
              radioListView.currentIndex = index
            }
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
          radioPlayer.toggleRadio()
        }

        width: 60
        height: 60
    }

    RadioPlayer {
        id: radioPlayer

        property var currentItem: undefined

        radioUrl: currentItem ? currentItem.url_resolved : ""
        icecastHint: currentItem ? /MP3|mp3|AAC/.test(currentItem.codec) : false
        audioOutput: AudioOutput {
            volume: 0.3
        }
    }
}
