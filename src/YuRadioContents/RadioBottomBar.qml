pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Controls.Material

import YuRadioContents
import Main

RadioBottomBarDrawer {
    id: root

    required property GridView gridView
    required property StackView stackView
    required property MusicInfoModel musicInfoModel

    property Component blurBehindBackground: MultiEffect {
        source: effectSource
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 64
        blur: 0.95
        saturation: -0.3

        Rectangle {
            anchors.fill: parent
            color: AppConfig.isDarkTheme ? root.Material.background.lighter(1.4) : root.Material.background.darker(1.05)
        }
    }

    property Component normalBackground: NormalBackground {}

    component NormalBackground: Rectangle {
        color: AppConfig.isDarkTheme ? root.Material.background.lighter(1.4) : root.Material.background.darker(1.05)
    }

    anchors {
        bottom: parent.bottom
        left: parent.left
        right: parent.right
    }

    maximumHeight: parent.height * 2 / 3
    minimumHeight: 0

    background: AppSettings.enableBottomBarBlur ? blurBehindBackground : normalBackground

    states: [
        State {
            name: "hasCurrentItem"
            when: MainRadioPlayer.currentItem.isValid()

            PropertyChanges {
                root.minimumHeight: Math.max(parent.height / 12, 70 * AppSettings.fontScale, 70)
            }
        }
    ]

    transitions: [
        Transition {
            to: "hasCurrentItem"

            PropertyAnimation {
                target: root
                properties: "minimumHeight"
                duration: 300
                easing.type: Easing.OutExpo
            }
        }
    ]

    ShaderEffectSource {
        id: effectSource

        anchors.fill: parent

        sourceItem: root.gridView
        sourceRect: Qt.rect(0, root.gridView.height, root.width, root.height)
        visible: false
    }

    Component {
        id: locationPage

        RadioStationLocationPage {
            stationLatitude: bottomBarContents.stationLatitude
            stationLongitude: bottomBarContents.stationLongitude
        }
    }

    RadioBottomBarContents {
        id: bottomBarContents

        property real stationLatitude
        property real stationLongitude

        anchors.fill: parent

        bottomBarDrawer: root
        musicInfoModel: root.musicInfoModel
        onShowRadioStationLocationRequested: (stationLat, stationLong) => {
            stationLatitude = stationLat;
            stationLongitude = stationLong;
            root.stackView.push(locationPage);
        }
    }

    RoundButton {
        anchors {
            bottom: parent.top
            right: parent.right
            rightMargin: 8
            bottomMargin: 20
        }
        width: 60
        height: 60

        icon.source: MainRadioPlayer.playing ? "images/pause.svg" : "images/play.svg"
        icon.width: width / 2
        icon.height: height / 2

        opacity: root.progress

        visible: !bottomBarContents.playerButtonVisible
        onClicked: {
            MainRadioPlayer.toggle();
        }
    }
}
