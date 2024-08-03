pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import "radiobrowser.mjs" as RadioBrowser

import YuRadioContents
import network

Item {
    id: root

    focus: true

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.leftMargin: 15
        anchors.rightMargin: 5

        Image {
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            fillMode: Image.PreserveAspectFit
            source: "images/shortwave.svg"
        }

        Label {
            text: qsTr("About")
            font.pointSize: 18
        }

        Rectangle {
            color: Material.foreground
            implicitWidth: parent.width * 2 / 3
            implicitHeight: 1
        }

        Label {
            Layout.fillWidth: true
            Layout.topMargin: 5

            textFormat: Text.MarkdownText
            text: qsTr(`**YuRadio** is a multiplatform application built with Qt.<br/>
            <br/>
            In Android, it uses built-in _**ExoPlayer**_ for audio playback.<br/>
            All other platforms will use Qt's _**QMediaPlayer**_
            `)

            wrapMode: Text.WordWrap
        }

        Button {
            Layout.fillWidth: true
            Layout.topMargin: 20
            Material.background: Material.color(Material.Grey, Material.ShadeA200)
            Material.foreground: Material.color(Material.Grey, Material.Shade100)

            text: "Github"

            onClicked: {
                Qt.openUrlExternally("https://github.com/yunag/YuRadio");
            }

            icon.source: "images/github-mark.svg"
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
