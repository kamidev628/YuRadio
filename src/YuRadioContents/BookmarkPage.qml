pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import YuRadioContents
import network
import Main

StackViewPage {
    id: root

    required property RadioDrawer drawer
    required property NetworkManager networkManager
    required property MusicInfoModel musicInfoModel

    morphHeaderBackground: !bookmarkGridView.atYBeginning
    focus: true

    RadioStationView {
        id: bookmarkGridView

        bottomBar: bottomBarDrawer
        networkManager: root.networkManager
        moreOptionsMenu.enableSynchronization: true
        stationAtIndex: index => bookmarkGridView.model[index]
        sortHeader.height: 0

        model: AppStorage.bookmarkModel
    }

    RadioBottomBar {
        id: bottomBarDrawer

        interactive: !root.drawer.opened || AppConfig.isPortraitLayout
        gridView: bookmarkGridView
        stackView: root.StackView.view
        musicInfoModel: root.musicInfoModel
    }
}
