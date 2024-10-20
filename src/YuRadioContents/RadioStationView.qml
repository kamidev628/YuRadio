pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

import "radiobrowser.mjs" as RadioBrowser

import YuRadioContents
import network

FilledGridView {
    id: root

    required property RadioBottomBar bottomBar
    required property NetworkManager networkManager
    required property var stationAtIndex

    property alias moreOptionsMenu: moreOptionsMenu
    property alias sortHeader: radioListViewHeader

    property real prevContentY: -1
    property real headerHeight: radioListViewHeader.height

    signal moreOptionsMenuRequested(int index, Item context)

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        bottom: bottomBar.detached ? parent.bottom : bottomBar.top
    }

    topMargin: radioListViewHeader.height

    onContentYChanged: {
        if (prevContentY !== -1) {
            const movingDelta = contentY - prevContentY;
            root.headerHeight = Utils.clamp(root.headerHeight - movingDelta, 0, radioListViewHeader.height);
        }
        prevContentY = contentY;
    }

    RadioStationsViewHeader {
        id: radioListViewHeader

        anchors {
            left: parent.left
            top: parent.top
            right: parent.right
            topMargin: root.headerHeight - height
        }
        z: 0
        height: implicitHeight
        visible: root.headerHeight > 0
    }

    displayMarginEnd: bottomBar.height
    currentIndex: -1

    minimumItemWidth: 400 * AppSettings.fontScale
    cellHeight: (AppSettings.stationDelegateHeightPolicy === "small" ? 80 : 100) * AppSettings.fontScale

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
