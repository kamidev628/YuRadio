pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

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
        interactive: !(root.drawer.opened && !Window.window.isDesktopLayout)
        gridView: bookmarkGridView
        stackView: root.StackView.view
        musicInfoModel: root.musicInfoModel
    }
}
