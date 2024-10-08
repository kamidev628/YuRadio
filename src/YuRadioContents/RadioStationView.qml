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

    required property var stationAtIndex

    property alias moreOptionsMenu: moreOptionsMenu

    signal moreOptionsMenuRequested(int index, Item context)

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        bottom: bottomBar.detached ? parent.bottom : bottomBar.top
    }

    displayMarginEnd: bottomBar.height
    currentIndex: -1

    minimumItemWidth: 400 * AppSettings.fontScale
    cellHeight: 100 * AppSettings.fontScale

    clip: true
    highlightFollowsCurrentItem: true
    focus: true

    boundsMovement: Flickable.StopAtBounds
    boundsBehavior: AppConfig.isMobile ? Flickable.DragOverBounds : Flickable.StopAtBounds

    /* NOTE: QTBUG-117035 Uncomment when supported */
    // headerPositioning: AppConfig.isMobile ? GridView.PullBackHeader : GridView.InlineHeader

    highlight: ListViewHighlightBar {}

    Binding {
        when: !AppSettings.enableSelectionAnimation
        root.highlightMoveDuration: 0
    }

    ScrollIndicator.vertical: ScrollIndicator { 
        visible: AppConfig.isMobile
    }
    ScrollBar.vertical: ScrollBar {
        visible: !AppConfig.isMobile
    }

    delegate: RadioStationDelegate {
        id: delegate

        focus: true

        onMoreOptionsMenuRequested: context => {
            root.moreOptionsMenu.station = root.stationAtIndex(delegate.index);
            root.moreOptionsMenu.popup(context, 0, 0);
        }

        onClicked: {
            if (currentStation) {
                MainRadioPlayer.toggle();
            } else {
                RadioBrowser.click(root.networkManager.baseUrl, delegate.uuid);
                MainRadioPlayer.currentItem = root.stationAtIndex(delegate.index);
                root.currentIndex = delegate.index;
                Qt.callLater(MainRadioPlayer.play);
            }
        }
    }

    MoreOptionsMenu {
        id: moreOptionsMenu

        networkManager: root.networkManager
    }
}
