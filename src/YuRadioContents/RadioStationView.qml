pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import "radiobrowser.mjs" as RadioBrowser

import YuRadioContents
import network

FilledGridView {
    id: root

    required property RadioBottomBar bottomBar
    required property NetworkManager networkManager

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        bottom: bottomBar.top
    }

    displayMarginEnd: bottomBar.height
    currentIndex: -1

    minimumItemWidth: 400
    cellHeight: 100

    clip: true
    focus: true
    highlightFollowsCurrentItem: true

    boundsMovement: Flickable.StopAtBounds
    boundsBehavior: AppConfig.isMobile ? Flickable.DragOverBounds : Flickable.StopAtBounds
    highlight: ListViewHighlightBar {}

    Binding {
        when: !AppSettings.enableSelectionAnimation
        root.highlightMoveDuration: 0
    }

    ScrollBar.vertical: ScrollBar {
        visible: !AppConfig.isMobile
    }

    delegate: RadioStationDelegate {
        id: delegate

        focus: true
        focusPolicy: Qt.StrongFocus
        moreOptionsMenu: moreOptionsMenu

        onClicked: {
            if (currentStation) {
                MainRadioPlayer.toggle();
            } else {
                RadioBrowser.click(root.networkManager.baseUrl, stationuuid);
                MainRadioPlayer.currentItem = Object.assign({}, root.model.get(delegate.index));
                root.currentIndex = delegate.index;
                Qt.callLater(MainRadioPlayer.play);
            }
        }
    }

    component EnhancedMenuItem: MenuItem {
        focusPolicy: Qt.TabFocus
    }

    Menu {
        id: moreOptionsMenu

        property int index: -1
        property string stationuuid: index !== -1 ? root.model.get(index).stationuuid : ""
        property bool bookmarkAdded
        property bool canVote


        onAboutToShow: {
            bookmarkAdded = Storage.existsBookmark(stationuuid);
            canVote = !Storage.existsVote(stationuuid);
        }

        EnhancedMenuItem {
            text: moreOptionsMenu.bookmarkAdded ? qsTr("Delete bookmark") : qsTr("Add bookmark")
            icon.source: moreOptionsMenu.bookmarkAdded ? "images/bookmark-added.svg" : "images/bookmark.svg"

            onTriggered: {
                if (moreOptionsMenu.bookmarkAdded) {
                    Storage.deleteBookmark(moreOptionsMenu.stationuuid);
                } else {
                    Storage.addBookmark(root.model.get(moreOptionsMenu.index));
                }
            }
        }

        EnhancedMenuItem {
            text: moreOptionsMenu.canVote ? qsTr("Vote") : qsTr("Already Voted")
            icon.source: moreOptionsMenu.canVote ? "images/thumb-up.svg" : "images/thumb-up-filled.svg"
            enabled: moreOptionsMenu.canVote

            onTriggered: {
                if (moreOptionsMenu.canVote) {
                    Storage.addVote(moreOptionsMenu.stationuuid);
                    RadioBrowser.vote(root.networkManager.baseUrl, moreOptionsMenu.stationuuid);
                }
            }
        }
    }
}
