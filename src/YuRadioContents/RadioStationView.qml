pragma ComponentBehavior: Bound

import QtQuick

import "radiobrowser.mjs" as RadioBrowser

import YuRadioContents
import network

FilledGridView {
    id: root

    required property RadioBottomBar bottomBar
    required property NetworkManager networkManager

    displayMarginEnd: bottomBar.height
    currentIndex: -1

    minimumItemWidth: 400
    cellHeight: 100

    clip: true
    focus: true
    highlightFollowsCurrentItem: false

    boundsMovement: Flickable.StopAtBounds
    boundsBehavior: Flickable.DragOverBounds
    highlight: ListViewHighlightBar {}

    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        bottom: bottomBar.top
    }

    delegate: RadioStationDelegate {
        id: delegate

        focus: true
        focusPolicy: Qt.StrongFocus
        networkManager: root.networkManager

        onCurrentStationChanged: {
            if (currentStation) {
                Qt.callLater(() => {
                    root.currentIndex = Qt.binding(() => currentStation ? index : -1);
                });
            }
        }

        onClicked: {
            if (GridView.view.currentIndex == delegate.index) {
                MainRadioPlayer.toggle();
            } else {
                RadioBrowser.click(root.networkManager.baseUrl, stationuuid);
                root.currentIndex = delegate.index;
                MainRadioPlayer.currentItem = Object.assign({}, root.model.get(delegate.index));
                Qt.callLater(MainRadioPlayer.play);
            }
        }
    }
}
