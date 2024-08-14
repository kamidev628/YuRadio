pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import Main

FocusScope {
    id: root

    implicitHeight: 70

    required property RadioBottomBarDrawer bottomBarDrawer
    property MusicInfoModel musicInfoModel: bottomBarDrawer.musicInfoModel

    readonly property DragHandler bottomBarDragHandler: bottomBarDrawer.dragHandler

    property var musicInfo
    property string streamTitle: MainRadioPlayer.streamTitle
    property string lastStreamTitle: ""

    property alias playerButton: playerButton

    property real stationLatitude: MainRadioPlayer.currentItem?.geo_lat ?? 0
    property real stationLongitude: MainRadioPlayer.currentItem?.geo_long ?? 0
    property string stationName: MainRadioPlayer.currentItem?.name ?? ""
    property string stationTags: MainRadioPlayer.currentItem?.tags ?? ""
    property string stationUrl: MainRadioPlayer.currentItem?.url_resolved ?? ""
    property string stationIcon: MainRadioPlayer.currentItem?.favicon ?? ""
    property string stationHomepage: MainRadioPlayer.currentItem?.homepage ?? ""
    property string stationCountry: MainRadioPlayer.currentItem?.country ?? ""
    property string stationLanguage: MainRadioPlayer.currentItem?.language ?? ""

    signal showRadioStationLocationRequested(real staitonLat, real stationLong)

    Binding {
        when: mainFlickable.dragging
        root.bottomBarDragHandler.enabled: false
    }

    states: [
        State {
            name: "dragStarted"
            when: root.bottomBarDrawer.height > root.implicitHeight + 100

            PropertyChanges {
                stationInfoColumn.visible: true
                playerButton.visible: false
                closeButton.visible: false
                secondaryColumnLayout.visible: true
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

                Image {
                    id: stationImage

                    smooth: true
                    source: root.stationIcon ? root.stationIcon : (AppSettings.isDarkTheme ? "images/radio-white.png" : "images/radio.png")

                    fillMode: Image.PreserveAspectFit

                    Layout.minimumHeight: Math.min(root.width / 3, root.height - 8, 300, mainColumn.implicitHeight)
                    Layout.minimumWidth: Layout.minimumHeight
                    Layout.maximumHeight: Layout.minimumHeight
                    Layout.maximumWidth: Layout.minimumHeight

                    Layout.leftMargin: 10
                    Layout.fillHeight: true
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: bottomBarTextColumn.implicitHeight

                    Column {
                        id: bottomBarTextColumn

                        width: parent.width

                        Label {
                            id: stationName
                            text: root.stationName ? root.stationName : qsTr("Station")

                            width: parent.width
                            elide: Text.ElideRight
                            font.bold: true
                            font.pointSize: 16
                        }

                        Label {
                            id: musicTags
                            text: root.stationTags ? root.stationTags : '⸻'

                            Binding {
                                when: progressBar.visible || errorText.visible
                                musicTags.text: ""
                            }

                            maximumLineCount: 3

                            width: parent.width
                            elide: Text.ElideRight
                            font.pointSize: 13

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
                                indeterminate: true
                                anchors.fill: parent
                                visible: MainRadioPlayer.loading && !MainRadioPlayer.playing
                            }
                        }

                        ColumnLayout {
                            id: stationInfoColumn
                            visible: false

                            width: parent.width

                            spacing: 2

                            Label {
                                id: country
                                Layout.topMargin: 20
                                Layout.fillWidth: true

                                visible: root.stationCountry

                                text: qsTr("Country: %1").arg(root.stationCountry)
                                font.pointSize: 14
                                wrapMode: Text.WordWrap
                            }

                            Label {
                                id: language

                                Layout.fillWidth: true

                                visible: root.stationLanguage

                                text: root.stationLanguage.includes(",") ? qsTr("Languages: %1").arg(root.stationLanguage) : qsTr("Language: %1").arg(root.stationLanguage)
                                font.pointSize: 14
                                wrapMode: Text.WordWrap
                            }

                            ClickableLink {
                                id: homePage

                                visible: root.stationHomepage
                                linkText: qsTr('Homepage')
                                link: root.stationHomepage

                                font.pointSize: 14
                            }

                            Button {
                                id: mapButton

                                flat: true
                                visible: root.stationLatitude && root.stationLongitude

                                text: qsTr('Show on the map')
                                icon.source: "images/map.svg"

                                onClicked: {
                                    root.showRadioStationLocationRequested(root.stationLatitude, root.stationLongitude);
                                }
                            }
                        }
                    }
                }

                IconButton {
                    id: playerButton

                    Layout.preferredWidth: 40
                    Layout.preferredHeight: Layout.preferredWidth

                    icon.source: MainRadioPlayer.playing ? "images/pause.svg" : "images/play.svg"
                    icon.sourceSize: Qt.size(height, height)
                    icon.color: Material.color(Material.Grey, AppSettings.isDarkTheme ? Material.Shade400 : Material.Shade800)

                    smooth: true

                    onClicked: {
                        MainRadioPlayer.toggle();
                    }
                }

                IconButton {
                    id: closeButton

                    Layout.rightMargin: 10
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: Layout.preferredWidth

                    icon.source: "images/close.svg"
                    icon.sourceSize: Qt.size(height, height)
                    icon.color: Material.color(Material.Grey, AppSettings.isDarkTheme ? Material.Shade400 : Material.Shade800)

                    smooth: true

                    onClicked: {
                        MainRadioPlayer.stop();
                        MainRadioPlayer.currentItem = undefined;
                    }
                }
            }

            ColumnLayout {
                id: secondaryColumnLayout
                visible: false

                Layout.fillWidth: true
                Layout.fillHeight: true

                Layout.topMargin: 20
                Layout.leftMargin: 10

                Label {
                    visible: !musicInfoRow.visible && !busyIndicator.visible
                    text: qsTr("Music Info is not avaialble")
                    opacity: 0.5
                    font.pointSize: 16
                    Layout.topMargin: 15
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                BusyIndicator {
                    id: busyIndicator
                    visible: root.musicInfoModel.status == MusicInfoModel.Loading
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                RowLayout {
                    id: musicInfoRow
                    visible: root.musicInfoModel.status == MusicInfoModel.Ready && root.musicInfo

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    spacing: 20

                    Image {
                        source: root.musicInfo?.coverUrls[0] ?? ''

                        Layout.minimumWidth: Math.min(mainColumn.width * 4 / 9, 300)
                        Layout.minimumHeight: Layout.minimumWidth

                        Layout.maximumWidth: Layout.minimumWidth
                        Layout.maximumHeight: Layout.minimumHeight

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        fillMode: Image.PreserveAspectFit
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Label {
                            text: qsTr("<b>Album</b>: %1").arg(root.musicInfo?.albumName)
                            font.pointSize: 14
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            textFormat: Text.RichText
                        }
                        Label {
                            text: qsTr("<b>Song</b>: %1").arg(root.musicInfo?.songName)
                            font.pointSize: 14
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            textFormat: Text.RichText
                        }
                        Label {
                            text: qsTr("<b>Artist</b>: %1").arg(root.musicInfo?.artistNames.join(", "))
                            font.pointSize: 14
                            Layout.fillWidth: true
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
                    text: qsTr("Provided for: %1").arg(root.streamTitle)
                    visible: musicInfoRow.visible
                    opacity: 0.6
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Timer {
        id: updateMusicInfoTimer
        interval: 500
        repeat: false

        running: root.streamTitle && root.streamTitle !== root.lastStreamTitle && Application.state == Qt.ApplicationActive && secondaryColumnLayout.visible

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
        target: MainRadioPlayer.mediaItem
        function onSourceChanged() {
            root.musicInfo = null;
        }
    }

    Connections {
        target: MainRadioPlayer

        function onStreamTitleChanged() {
            root.musicInfoModel.searchTerm = root.streamTitle;
        }
    }
}
