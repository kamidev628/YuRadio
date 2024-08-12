pragma ComponentBehavior: Bound

import QtQuick

import YuRadioContents
import network
import Main

Item {
    id: root

    focus: true

    required property RadioDrawer drawer
    required property NetworkManager networkManager
    required property MusicInfoModel musicInfoModel

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
        musicInfoModel: root.musicInfoModel
    }

    Connections {
        target: root.drawer
        function onOpened() {
            bottomBarDrawer.close();
        }
    }
}
