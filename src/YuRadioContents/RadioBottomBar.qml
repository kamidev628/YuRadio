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

    property real radius

    readonly property real preferredSideMargins: parent.width / 5
    readonly property real maximumWidth: 800
    readonly property real sideMargins: (parent.width - maximumWidth) / 2 > preferredSideMargins ? (parent.width - maximumWidth) / 2 : preferredSideMargins

    detached: ApplicationWindow.window.width > AppConfig.detachBottomBarWidth

    property Component blurBehindBackground: NormalBackground {
        MultiEffect {
            id: blurBehindEffect

            anchors.fill: parent

            visible: MainRadioPlayer.currentItem.isValid()

            maskEnabled: visible
            maskSource: bottomBarMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0

            source: effectSource
            autoPaddingEnabled: false
            blurEnabled: visible
            blurMax: 64
            blur: 0.95
            saturation: -0.3
        }

        Rectangle {
            id: bottomBarMask

            anchors.fill: parent

            visible: false

            layer.enabled: true
            layer.smooth: true

            radius: root.radius
        }

        ShaderEffectSource {
            id: effectSource

            sourceItem: root.gridView
            sourceRect: Qt.rect(root.x, root.y, root.width, root.height)
            visible: false
        }
    }

    property Component normalBackground: NormalBackground {}

    component NormalBackground: Rectangle {
        color: AppConfig.isDarkTheme ? root.Material.background.lighter(1.4) : root.Material.background.darker(1.05)
        radius: root.radius
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
            name: "detached"
            when: root.detached && MainRadioPlayer.currentItem.isValid()
            extend: "hasCurrentItem"

            PropertyChanges {
                root.anchors {
                    leftMargin: root.sideMargins
                    rightMargin: root.sideMargins
                    bottomMargin: 20
                }

                bottomBarContents.anchors {
                    leftMargin: 10
                    rightMargin: 10
                    topMargin: 6
                    bottomMargin: 6
                }

                root.radius: root.height / 3
            }
        },
        State {
            name: "hasCurrentItem"
            when: MainRadioPlayer.currentItem.isValid()

            PropertyChanges {
                root.minimumHeight: 70 * Math.max(AppSettings.fontScale, 1.0)
            }
        }
    ]

    transitions: [
        Transition {
            to: "detached"

            PropertyAnimation {
                target: root.anchors
                properties: "leftMargin,rightMargin,bottomMargin"
                duration: 200
                easing.type: Easing.InQuad
            }
            PropertyAnimation {
                target: root
                property: "radius"
                duration: 100
            }
        },
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
        anchors.bottomMargin: 10

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
            MainRadioPlayer.toggleRadio();
        }
    }
}
