pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

import YuRadioContents

Loader {
    id: root

    required property int index
    required property int bitrate

    required property list<string> tags

    required property string name
    required property string countryCode
    required property string uuid

    required property url favicon
    required property url url

    readonly property bool currentStation: MainRadioPlayer.currentItem.isValid() && MainRadioPlayer.currentItem.uuid == uuid
    readonly property Component mainComponent: MainComponent {}
    readonly property Component sceletonComponent: SceletonComponent {}
    readonly property FilledGridView view: GridView.view as FilledGridView

    signal clicked
    signal moreOptionsMenuRequested(Item context)

    height: view.cellHeight
    width: view.cellWidth
    focus: true

    Component.onCompleted: {
        if (view.numItemsInRow >= 3) {
            sourceComponent = sceletonComponent;
            Utils.execLater(root, Utils.getRandomInt(200, 300), () => sourceComponent = mainComponent);
        } else {
            sourceComponent = mainComponent;
        }
    }

    component SceletonComponent: Item {
        Rectangle {
            anchors.fill: parent
            anchors.margins: 5

            opacity: 0.3
            radius: 8

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: AppConfig.isDarkTheme ? "#29323c" : "#e6e9f0"
                }

                GradientStop {
                    position: 1
                    color: AppConfig.isDarkTheme ? "#474445" : "#eef1f5"
                }
                orientation: Gradient.Vertical
            }
        }
    }

    component MainComponent: ItemDelegate {
        id: delegate

        onClicked: root.clicked()

        Accessible.name: root.name + " " + root.tags

        focusPolicy: Qt.StrongFocus
        focus: true

        Binding {
            when: root.currentStation
            target: delegate.background
            property: "color"
            value: Qt.color("lightsteelblue").darker(AppConfig.isDarkTheme ? 1.8 : 1.05)
        }

        RowLayout {
            anchors.fill: parent

            RadioImage {
                id: radioImage

                Layout.fillHeight: true
                Layout.leftMargin: 5
                Layout.topMargin: 5
                Layout.bottomMargin: 5
                Layout.preferredWidth: height

                fallbackSource: AppConfig.isDarkTheme ? "images/radio-white.png" : "images/radio.png"
                targetSource: root.favicon

                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true

                IconImage {
                    anchors {
                        left: parent.left
                        top: parent.top
                        leftMargin: 5
                        topMargin: 5
                    }

                    opacity: 0.8
                    source: root.countryCode ? `https://flagsapi.com/${root.countryCode}/flat/24.png` : ''
                    sourceSize: Qt.size(24, 24)
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.leftMargin: 5
                Layout.rightMargin: 5

                Timer {
                    id: updateElideTimer
                    interval: 50
                    repeat: false

                    onRunningChanged: {
                        if (running) {
                            stationName.elide = Text.ElideNone;
                            stationTags.elide = Text.ElideNone;
                        }
                    }

                    onTriggered: {
                        stationName.elide = Text.ElideRight;
                        stationTags.elide = Text.ElideRight;
                    }
                }

                ScalableLabel {
                    id: stationName
                    Layout.fillWidth: true

                    text: root.name ? root.name : "Unknown Station"
                    font.bold: true
                    fontPointSize: 15
                    clip: true

                    onWidthChanged: updateElideTimer.restart()
                }

                ScalableLabel {
                    id: stationTags
                    Layout.fillWidth: true

                    text: root.tags.join(", ")
                    fontPointSize: 14
                    clip: true

                    onWidthChanged: updateElideTimer.restart()
                }
            }

            IconButton {
                id: moreOptions

                Layout.alignment: Qt.AlignVCenter
                Layout.fillHeight: true
                implicitWidth: 64
                Accessible.name: qsTr("More options menu")

                icon.source: "images/more-vert.svg"
                icon.width: 32
                icon.height: 32
                icon.color: Material.color(Material.Grey, AppConfig.isDarkTheme ? Material.Shade400 : Material.Shade800)
                opacity: 0.5

                onClicked: {
                    root.moreOptionsMenuRequested(moreOptions);
                }
            }
        }

        ScalableLabel {
            anchors {
                bottom: parent.bottom
                right: parent.right
                rightMargin: 10
                bottomMargin: 5
            }

            text: qsTr("%1 kbps").arg(root.bitrate ? root.bitrate : "-")
            fontPointSize: 8
            opacity: 0.8
        }
    }
}
