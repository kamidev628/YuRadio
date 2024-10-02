pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import YuRadioContents
import Main

Drawer {
    id: root

    modal: false
    interactive: false
    closePolicy: Popup.NoAutoClose

    property ApplicationWindow window: ApplicationWindow.window as ApplicationWindow

    required property MusicInfoModel musicInfoModel
    property var musicInfo

    property string lastStreamTitle
    property string streamTitle: MainRadioPlayer.streamTitle

    property radiostation radioStation: MainRadioPlayer.currentItem

    signal showRadioStationLocationRequested(real staitonLat, real stationLong)

    Material.roundedScale: Material.NotRounded

    edge: Qt.RightEdge
    y: window.header.height
    width: Math.min(AppConfig.radioStationInfoPanelWidth, implicitWidth)
    height: window.height - window.header.height

    Flickable {
        id: flickable

        anchors.fill: parent
        clip: true

        contentHeight: mainColumn.implicitHeight
        contentWidth: width

        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: mainColumn

            width: parent.width

            RadioImage {
                id: radioStationImage

                Layout.fillWidth: true
                Layout.leftMargin: 15
                Layout.rightMargin: 15
                Layout.topMargin: 10
                Layout.preferredHeight: width

                targetSource: root.radioStation.favicon
                fallbackSource: {
                    if (!MainRadioPlayer.currentItem.isValid()) {
                        return "";
                    }
                    return AppConfig.isDarkTheme ? "images/radio-white.png" : "images/radio.png";
                }
                fillMode: Image.PreserveAspectFit

                smooth: true
            }

            ScalableLabel {
                id: radioStationNameLabel

                Layout.fillWidth: true
                Layout.leftMargin: 15
                Layout.rightMargin: 15

                wrapMode: Text.WordWrap
                text: root.radioStation.name
                font.bold: true
                fontPointSize: 16

                horizontalAlignment: Text.AlignHCenter
            }

            ScalableLabel {
                id: radioStationTags

                Layout.fillWidth: true
                Layout.leftMargin: 15
                Layout.rightMargin: 15

                wrapMode: Text.WordWrap
                maximumLineCount: 3
                text: root.radioStation.tags.join(", ")
                fontPointSize: 13
            }

            ColumnLayout {
                id: stationInfoColumn

                Layout.fillWidth: true
                Layout.leftMargin: 15
                Layout.rightMargin: 15

                spacing: 5

                Item {
                    id: stationInfoColumnSpacer

                    implicitHeight: 20
                }

                ScalableLabel {
                    id: country

                    Layout.fillWidth: true
                    visible: root.radioStation.country

                    text: qsTr("Country: %1").arg(root.radioStation.country)
                    fontPointSize: 12
                    wrapMode: Text.WordWrap
                }

                ScalableLabel {
                    id: language

                    Layout.fillWidth: true
                    visible: root.radioStation.language

                    text: root.radioStation.language.includes(",") ? qsTr("Languages: %1").arg(root.radioStation.language) : qsTr("Language: %1").arg(root.radioStation.language)
                    fontPointSize: 12
                    wrapMode: Text.WordWrap
                }

                ScalableLabel {
                    id: bitrate

                    Layout.fillWidth: true
                    visible: root.radioStation.bitrate

                    text: qsTr("Bitrate: %1").arg(root.radioStation.bitrate)
                    fontPointSize: 12
                }

                ClickableLink {
                    id: homePage

                    visible: root.radioStation.homepage

                    linkText: qsTr('Homepage')
                    link: root.radioStation.homepage
                    fontPointSize: 12
                }

                ScalableButton {
                    id: mapButton

                    Layout.fillWidth: true

                    flat: true
                    visible: root.radioStation.geoLatitude && root.radioStation.geoLongitude

                    text: qsTr('Show on the map')
                    icon.source: "images/map.svg"

                    onClicked: {
                        root.showRadioStationLocationRequested(root.radioStation.geoLatitude, root.radioStation.geoLongitude);
                    }
                }
            }

            ColumnLayout {
                id: secondaryColumnLayout

                Layout.leftMargin: 15
                Layout.rightMargin: 15
                Layout.fillWidth: true

                ScalableLabel {
                    Layout.topMargin: 15
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3

                    text: qsTr("Music Info is not avaialble")
                    fontPointSize: 15

                    visible: !musicInfoRow.visible && !busyIndicator.visible
                    opacity: 0.5
                }

                BusyIndicator {
                    id: busyIndicator

                    Layout.fillWidth: true

                    visible: root.musicInfoModel.status == MusicInfoModel.Loading
                }

                ColumnLayout {
                    id: musicInfoRow

                    Layout.topMargin: 20
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    visible: root.musicInfoModel.status == MusicInfoModel.Ready && root.musicInfo != null

                    Image {
                        id: musicInfoRowImage

                        Layout.fillWidth: true
                        Layout.preferredHeight: width

                        source: root.musicInfo?.coverUrls[0] ?? ''
                        fillMode: Image.PreserveAspectFit

                        BusyIndicator {
                            anchors.centerIn: parent
                            visible: musicInfoRowImage.status == Image.Loading
                        }
                    }

                    ScalableLabel {
                        Layout.fillWidth: true

                        text: qsTr("<b>Album</b>: %1").arg(root.musicInfo?.albumName)
                        fontPointSize: 13
                        wrapMode: Text.WordWrap
                        textFormat: Text.RichText
                    }

                    ScalableLabel {
                        Layout.fillWidth: true

                        text: qsTr("<b>Song</b>: %1").arg(root.musicInfo?.songName)
                        fontPointSize: 13
                        wrapMode: Text.WordWrap
                        textFormat: Text.RichText
                    }

                    ScalableLabel {
                        Layout.fillWidth: true

                        text: qsTr("<b>Artist</b>: %1").arg(root.musicInfo?.artistNames.join(", "))
                        fontPointSize: 13
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

                        Layout.fillWidth: true

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

                ScalableLabel {
                    Layout.fillWidth: true

                    visible: musicInfoRow.visible
                    opacity: 0.7

                    text: qsTr("Provided for: %1").arg(root.streamTitle)
                    wrapMode: Text.WordWrap
                }

                Item {
                    Layout.fillHeight: true
                    Layout.minimumHeight: 5
                    Layout.verticalStretchFactor: Utils.maxInteger
                }
            }

            Item {
                id: verticalSpacer

                Layout.fillHeight: true
            }
        }
    }

    Timer {
        id: updateMusicInfoTimer

        interval: 500
        repeat: false

        running: root.streamTitle && root.streamTitle !== root.lastStreamTitle && Application.state == Qt.ApplicationActive && root.opened

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
