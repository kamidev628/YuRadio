pragma ComponentBehavior: Bound

import QtQuick

import YuRadioContents
import network

Item {
    id: root

    focus: true

    required property RadioDrawer drawer
    required property NetworkManager networkManager

    RadioStationView {
        id: bookmarkGridView

        bottomBar: bottomBarDrawer
        networkManager: root.networkManager

        model: Storage.bookmarkModel
    }

    RadioBottomBar {
        id: bottomBarDrawer
        gridView: bookmarkGridView
        stackView: root.StackView.view
    }

    Connections {
        target: root.drawer
        function onOpened() {
            bottomBarDrawer.close();
        }
    }
}
