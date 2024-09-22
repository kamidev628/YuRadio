pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import Main
import YuRadioContents

FocusScope {
    id: root

    required property RadioBottomBarDrawer bottomBarDrawer
    required property MusicInfoModel musicInfoModel

    property var musicInfo
    property var radioStation: MainRadioPlayer.currentItem

    property string lastStreamTitle: ""
    property string streamTitle: MainRadioPlayer.streamTitle

    property alias playerButtonVisible: playerButtonLoader.active

    signal showRadioStationLocationRequested(real staitonLat, real stationLong)

    implicitHeight: 70

    states: [
        State {
            name: "dragStarted"
            when: root.bottomBarDrawer.progress >= 0.3

            PropertyChanges {
                stationInfoColumn.visible: true
                playerButtonLoader.active: false
                closeButtonLoader.active: false
                secondaryColumnLayoutLoader.active: true
                bottomBarRowLayout.spacing: 20

                mainFlickable.anchors.leftMargin: 10
                mainFlickable.anchors.rightMargin: 10
                mainFlickable.anchors.topMargin: 10

                bottomBarTextColumn.anchors.rightMargin: 10

                stationName.wrapMode: Text.WordWrap
                musicTags.wrapMode: Text.WordWrap
            }
        }
    ]

    Binding {
        when: mainFlickable.dragging
        root.bottomBarDrawer.interactive: false
    }

    Flickable {
        id: mainFlickable

        anchors.fill: parent
        contentHeight: mainColumn.implicitHeight
        contentWidth: width

        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainColumn

            width: parent.width

            RowLayout {
                id: bottomBarRowLayout

                Layout.fillWidth: true

                RadioImage {
                    id: stationImage

                    Layout.minimumHeight: Math.min(root.width / 3, root.height - 8, 300)
                    Layout.minimumWidth: Layout.minimumHeight
                    Layout.maximumHeight: Layout.minimumHeight
                    Layout.maximumWidth: Layout.minimumHeight

                    Layout.leftMargin: 10
                    Layout.fillHeight: true

                    fallbackSource: AppConfig.isDarkTheme ? "images/radio-white.png" : "images/radio.png"
                    targetSource: root.radioStation?.favicon ?? ""
                    fillMode: Image.PreserveAspectFit

                    smooth: true
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: bottomBarTextColumn.implicitHeight

                    Column {
                        id: bottomBarTextColumn

                        width: parent.width

                        Label {
                            id: stationName

                            width: parent.width

                            text: root.radioStation?.name ?? qsTr("Station")
                            elide: Text.ElideRight
                            font.bold: true
                            font.pointSize: 16
                        }

                        Label {
                            id: musicTags

                            width: parent.width

                            text: {
                                if (progressBar.visible || errorText.visible) {
                                    return "";
                                }
                                return root.radioStation?.tags ?? '';
                            }
                            elide: Text.ElideRight
                            font.pointSize: 13
                            maximumLineCount: 3

                            Label {
                                id: errorText

                                anchors.fill: parent

                                Material.foreground: Material.Red
                                text: visible ? MainRadioPlayer.errorString : ``
                                elide: Text.ElideRight
                                visible: MainRadioPlayer.error != RadioPlayer.NoError && !progressBar.visible
                            }

                            ProgressBar {
                                id: progressBar

                                anchors.fill: parent

                                indeterminate: true
                                visible: MainRadioPlayer.loading && !MainRadioPlayer.playing
                            }
                        }

                        ColumnLayout {
                            id: stationInfoColumn

                            width: parent.width

                            visible: false
                            spacing: 2

                            Item {
                                id: stationInfoColumnSpacer

                                implicitHeight: 20
                            }

                            Label {
                                id: country

                                Layout.fillWidth: true
                                visible: root.radioStation?.country ?? false

                                text: qsTr("Country: %1").arg(root.radioStation?.country ?? "")
                                font.pointSize: 14
                                wrapMode: Text.WordWrap
                            }

                            Label {
                                id: language

                                readonly property string stationLanguage: root.radioStation?.language ?? ""

                                Layout.fillWidth: true
                                visible: root.radioStation?.language ?? false

                                text: stationLanguage.includes(",") ? qsTr("Languages: %1").arg(stationLanguage) : qsTr("Language: %1").arg(stationLanguage)
                                font.pointSize: 14
                                wrapMode: Text.WordWrap
                            }

                            Label {
                                id: bitrate

                                Layout.fillWidth: true
                                visible: root.radioStation?.bitrate ?? false

                                text: qsTr("Bitrate: %1").arg(root.radioStation?.bitrate ?? 0)
                                font.pointSize: 14
                            }

                            ClickableLink {
                                id: homePage

                                visible: root.radioStation?.homepage ?? false

                                linkText: qsTr('Homepage')
                                link: root.radioStation?.homepage ?? ""
                                font.pointSize: 14
                            }

                            Button {
                                id: mapButton

                                flat: true
                                visible: (root.radioStation?.geo_lat ?? false) && (root.radioStation?.geo_long ?? false)

                                text: qsTr('Show on the map')
                                icon.source: "images/map.svg"

                                onClicked: {
                                    root.showRadioStationLocationRequested(root.radioStation.geo_lat, root.radioStation.geo_long);
                                }
                            }
                        }
                    }
                }

                Loader {
                    id: playerButtonLoader

                    Layout.preferredWidth: 40
                    Layout.preferredHeight: Layout.preferredWidth
                    visible: active

                    active: true
                    sourceComponent: playerButtonComponent
                }

                Component {
                    id: playerButtonComponent

                    IconButton {
                        id: playerButton

                        icon.source: MainRadioPlayer.playing ? "images/pause.svg" : "images/play.svg"
                        icon.sourceSize: Qt.size(height, height)
                        icon.color: Material.color(Material.Grey, AppConfig.isDarkTheme ? Material.Shade400 : Material.Shade800)

                        smooth: true

                        onClicked: {
                            MainRadioPlayer.toggle();
                        }
                    }
                }

                Loader {
                    id: closeButtonLoader

                    Layout.rightMargin: 10
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: Layout.preferredWidth
                    visible: active

                    active: true
                    sourceComponent: closeButtonComponent
                }

                Component {
                    id: closeButtonComponent

                    IconButton {
                        id: closeButton

                        icon.source: "images/close.svg"
                        icon.sourceSize: Qt.size(height, height)
                        icon.color: Material.color(Material.Grey, AppConfig.isDarkTheme ? Material.Shade400 : Material.Shade800)

                        smooth: true

                        onClicked: {
                            MainRadioPlayer.stop();
                            MainRadioPlayer.currentItem = undefined;
                        }
                    }
                }
            }

            Loader {
                id: secondaryColumnLayoutLoader

                Layout.fillWidth: true
                Layout.fillHeight: true

                Layout.topMargin: 20
                Layout.leftMargin: 10
                visible: active

                active: false
                sourceComponent: secondaryColumnLayoutComponent
            }

            Component {
                id: secondaryColumnLayoutComponent

                ColumnLayout {
                    id: secondaryColumnLayout

                    Label {
                        Layout.topMargin: 15
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        horizontalAlignment: Text.AlignHCenter

                        text: qsTr("Music Info is not avaialble")
                        font.pointSize: 16

                        visible: !musicInfoRow.visible && !busyIndicator.visible
                        opacity: 0.5
                    }

                    BusyIndicator {
                        id: busyIndicator

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: root.musicInfoModel.status == MusicInfoModel.Loading
                    }

                    RowLayout {
                        id: musicInfoRow

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        visible: root.musicInfoModel.status == MusicInfoModel.Ready && root.musicInfo != null

                        spacing: 20

                        Image {
                            id: musicInfoRowImage

                            Layout.minimumWidth: Math.min(mainColumn.width * 4 / 9, 300)
                            Layout.minimumHeight: Layout.minimumWidth
                            Layout.maximumWidth: Layout.minimumWidth
                            Layout.maximumHeight: Layout.minimumHeight
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            source: root.musicInfo?.coverUrls[0] ?? ''
                            fillMode: Image.PreserveAspectFit

                            BusyIndicator {
                                anchors.centerIn: parent
                                visible: musicInfoRowImage.status == Image.Loading
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Label {
                                Layout.fillWidth: true

                                text: qsTr("<b>Album</b>: %1").arg(root.musicInfo?.albumName)
                                font.pointSize: 14
                                wrapMode: Text.WordWrap
                                textFormat: Text.RichText
                            }
                            Label {
                                Layout.fillWidth: true

                                text: qsTr("<b>Song</b>: %1").arg(root.musicInfo?.songName)
                                font.pointSize: 14
                                wrapMode: Text.WordWrap
                                textFormat: Text.RichText
                            }
                            Label {
                                Layout.fillWidth: true

                                text: qsTr("<b>Artist</b>: %1").arg(root.musicInfo?.artistNames.join(", "))
                                font.pointSize: 14
                                wrapMode: Text.WordWrap
                                textFormat: Text.RichText
                            }

                            Component {
                                id: itunesButton

                                ItunesButton {
                                    text: showTrackButtonLoader.buttonText
                                    link: root.musicInfo?.trackUrl ?? ''
                                }
                            }

                            Component {
                                id: spotifyButton

                                SpotifyButton {
                                    text: showTrackButtonLoader.buttonText
                                    link: root.musicInfo?.trackUrl ?? ''
                                }
                            }

                            Loader {
                                id: showTrackButtonLoader

                                property string buttonText: qsTr("Show track")
                                sourceComponent: {
                                    if (root.musicInfoModel.backendName == "itunes") {
                                        return itunesButton;
                                    }
                                    if (root.musicInfoModel.backendName == "spotify") {
                                        return spotifyButton;
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        Layout.bottomMargin: 6
                        Layout.fillWidth: true

                        visible: musicInfoRow.visible
                        opacity: 0.6

                        text: qsTr("Provided for: %1").arg(root.streamTitle)
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }

    Timer {
        id: updateMusicInfoTimer

        interval: 500
        repeat: false

        running: root.streamTitle && root.streamTitle !== root.lastStreamTitle && Application.state == Qt.ApplicationActive && secondaryColumnLayoutLoader.active

        onTriggered: {
            root.lastStreamTitle = root.streamTitle;
            root.musicInfoModel.refresh();
        }
    }

    Connections {
        target: root.musicInfoModel

        function onMusicInfoChanged() {
            root.musicInfo = root.musicInfoModel.musicInfo;
        }
    }

    Connections {
        target: MainRadioPlayer

        function onMediaItemChanged() {
            root.musicInfo = null;
        }

        function onStreamTitleChanged() {
            root.musicInfo = null;
            root.musicInfoModel.searchTerm = root.streamTitle;
        }
    }
}
