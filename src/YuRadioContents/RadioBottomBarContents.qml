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
    property radiostation radioStation: MainRadioPlayer.currentItem

    property string lastStreamTitle
    property string streamTitle: MainRadioPlayer.streamTitle

    property alias playerButtonVisible: playerButtonLoader.active

    signal showRadioStationLocationRequested(real staitonLat, real stationLong)

    implicitHeight: mainColumn.implicitHeight

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

                stationName.enableMarqueeEffect: false
                stationName.wrapMode: Text.Wrap
                stationTags.wrapMode: Text.Wrap
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

                    Layout.minimumHeight: Math.min(root.width / 3, root.height, 300)
                    Layout.minimumWidth: Layout.minimumHeight
                    Layout.maximumHeight: Layout.minimumHeight
                    Layout.maximumWidth: Layout.minimumHeight

                    Layout.leftMargin: 10
                    Layout.fillHeight: true

                    sourceSize: Qt.size(2 * 300 * Screen.devicePixelRatio, 2 * 300 * Screen.devicePixelRatio)

                    targetSource: root.radioStation.favicon
                    fillMode: Image.PreserveAspectFit

                    smooth: true
                    mipmap: true
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: bottomBarTextColumn.implicitHeight

                    Column {
                        id: bottomBarTextColumn

                        width: parent.width

                        MarqueeText {
                            id: stationName

                            width: parent.width

                            text: root.radioStation.name + " ".repeat(12)
                            elide: enableMarqueeEffect ? Text.ElideNone : Text.ElideRight
                            enableMarqueeEffect: AppSettings.enableTextScrolling

                            font.bold: true
                            fontPointSize: 16
                        }

                        ScalableLabel {
                            id: stationTags

                            width: parent.width

                            text: {
                                if (progressBar.visible || errorText.visible) {
                                    return "";
                                }
                                return root.radioStation.tags.join(", ");
                            }
                            elide: Text.ElideRight
                            fontPointSize: 13
                            maximumLineCount: 3

                            ScalableLabel {
                                id: errorText

                                anchors.fill: parent

                                Material.foreground: Material.Red
                                fontPointSize: 12

                                text: visible ? MainRadioPlayer.errorString : ""
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

                            ScalableLabel {
                                id: country

                                Layout.fillWidth: true
                                visible: root.radioStation.country

                                text: qsTr("Country: %1").arg(root.radioStation.country)
                                fontPointSize: 14
                                wrapMode: Text.Wrap
                            }

                            ScalableLabel {
                                id: language

                                Layout.fillWidth: true
                                visible: root.radioStation.language

                                text: root.radioStation.language.includes(",") ? qsTr("Languages: %1").arg(root.radioStation.language) : qsTr("Language: %1").arg(root.radioStation.language)
                                fontPointSize: 14
                                wrapMode: Text.Wrap
                            }

                            ScalableLabel {
                                id: bitrate

                                Layout.fillWidth: true
                                visible: root.radioStation.bitrate

                                text: qsTr("Bitrate: %1").arg(root.radioStation.bitrate)
                                fontPointSize: 14
                            }

                            ClickableLink {
                                id: homePage

                                visible: root.radioStation.homepage

                                linkText: qsTr('Homepage')
                                link: root.radioStation.homepage
                                fontPointSize: 14
                            }

                            ScalableButton {
                                id: mapButton

                                flat: true
                                visible: root.radioStation.geoLatitude && root.radioStation.geoLongitude

                                text: qsTr('Show on the map')
                                icon.source: "images/map.svg"

                                onClicked: {
                                    root.showRadioStationLocationRequested(root.radioStation.geoLatitude, root.radioStation.geoLongitude);
                                }
                            }
                        }
                    }
                }

                Loader {
                    id: playerButtonLoader

                    Layout.preferredWidth: 45
                    Layout.preferredHeight: 40
                    visible: active

                    active: true
                    sourceComponent: playerButtonComponent
                }

                Component {
                    id: playerButtonComponent

                    IconButton {
                        id: playerButton

                        text: MainRadioPlayer.playing ? qsTr("Pause") : qsTr("Play")

                        hoverEnabled: false
                        down: false

                        icon.source: MainRadioPlayer.playing ? "images/pause.svg" : "images/play.svg"
                        icon.width: height
                        icon.height: height
                        icon.color: Material.color(Material.Grey, AppConfig.isDarkTheme ? Material.Shade400 : Material.Shade800)

                        onClicked: {
                            MainRadioPlayer.toggleRadio();
                        }
                    }
                }

                Loader {
                    id: closeButtonLoader

                    Layout.rightMargin: 10
                    Layout.preferredWidth: 45
                    Layout.preferredHeight: 40
                    visible: active

                    active: true
                    sourceComponent: closeButtonComponent
                }

                Component {
                    id: closeButtonComponent

                    IconButton {
                        id: closeButton

                        text: qsTr("Stop audio and hide bottom bar")

                        icon.source: "images/close.svg"
                        icon.width: height
                        icon.height: height
                        icon.color: Material.color(Material.Grey, AppConfig.isDarkTheme ? Material.Shade400 : Material.Shade800)

                        hoverEnabled: false
                        down: false

                        onClicked: {
                            MainRadioPlayer.stop();
                            MainRadioPlayer.currentItem = RadioStationFactory.create();
                        }
                    }
                }
            }

            Loader {
                id: secondaryColumnLayoutLoader

                Layout.fillWidth: true
                Layout.fillHeight: true

                Layout.minimumHeight: 400

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

                    ScalableLabel {
                        Layout.topMargin: 15
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        horizontalAlignment: Text.AlignHCenter

                        text: qsTr("Music Info is not avaialble")
                        fontPointSize: 16

                        wrapMode: Text.Wrap
                        visible: !musicInfoRow.visible && !busyIndicator.visible
                        opacity: 0.5
                    }

                    BusyIndicator {
                        id: busyIndicator

                        Layout.fillWidth: true

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

                            ScalableLabel {
                                Layout.fillWidth: true

                                text: qsTr("<b>Album</b>: %1").arg(root.musicInfo?.albumName)
                                fontPointSize: 14
                                wrapMode: Text.Wrap
                                textFormat: Text.RichText
                            }
                            ScalableLabel {
                                Layout.fillWidth: true

                                text: qsTr("<b>Song</b>: %1").arg(root.musicInfo?.songName)
                                fontPointSize: 14
                                wrapMode: Text.Wrap
                                textFormat: Text.RichText
                            }
                            ScalableLabel {
                                Layout.fillWidth: true

                                text: qsTr("<b>Artist</b>: %1").arg(root.musicInfo?.artistNames.join(", "))
                                fontPointSize: 14
                                wrapMode: Text.Wrap
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

                    ScalableLabel {
                        Layout.fillWidth: true

                        visible: musicInfoRow.visible
                        opacity: 0.7

                        text: qsTr("Provided for: %1").arg(root.streamTitle)
                        wrapMode: Text.Wrap
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.minimumHeight: 5
                        Layout.verticalStretchFactor: Utils.maxInteger
                    }
                }
            }
        }
    }

    Timer {
        id: updateMusicInfoTimer

        interval: 500
        repeat: false

        running: root.streamTitle.length > 0 && root.streamTitle !== root.lastStreamTitle && Application.state == Qt.ApplicationActive && secondaryColumnLayoutLoader.active

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
            root.lastStreamTitle = "";
        }

        function onStreamTitleChanged() {
            root.musicInfo = null;
            root.musicInfoModel.searchTerm = root.streamTitle;
        }
    }
}
