import QtQuick
import QtQuick.Controls
import QtQuick.Effects

import network

Item {
    id: root

    focus: true

    ListView {
        id: favoriteListView

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
            enabled: isProcessing && !apiTimeoutTimer.running && favoriteListView.verticalOvershoot <= 0
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
            sourceItem: favoriteListView
            sourceRect: Qt.rect(0, favoriteListView.height, bottomBarDrawer.width, bottomBarDrawer.height)
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
}
