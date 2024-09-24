pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import YuRadioContents
import network
import Main

Item {
    id: root

    required property bool isDesktopLayout
    required property RadioDrawer drawer
    required property NetworkManager networkManager
    required property MusicInfoModel musicInfoModel

    focus: true

    RadioStationView {
        id: bookmarkGridView

        bottomBar: bottomBarDrawer
        networkManager: root.networkManager
        moreOptionsMenu.enableSynchronization: true
        stationAtIndex: index => bookmarkGridView.model[index]

        model: AppStorage.bookmarkModel
    }

    RadioBottomBar {
        id: bottomBarDrawer

        interactive: !root.drawer.opened || root.isDesktopLayout
        gridView: bookmarkGridView
        stackView: root.StackView.view
        musicInfoModel: root.musicInfoModel
    }
}
