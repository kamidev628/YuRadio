pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import YuRadioContents
import network
import Main

Item {
    id: root

    property bool morphBackground: !bookmarkGridView.atYBeginning

    required property RadioDrawer drawer
    required property NetworkManager networkManager
    required property MusicInfoModel musicInfoModel
    required property RadioStationInfoPanel stationInfoPanel

    focus: true

    RadioStationView {
        id: bookmarkGridView

        bottomBar: bottomBarDrawer
        networkManager: root.networkManager
        moreOptionsMenu.enableSynchronization: true
        stationAtIndex: index => bookmarkGridView.model[index]
        sortHeader.visible: false

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
