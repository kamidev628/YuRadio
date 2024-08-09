pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

Item {
    id: root

    focus: true

    states: [
        State {
            name: "desktopLayout"
            when: root.width > 600
            PropertyChanges {
                columnLayout.width: columnLayout.parent.width / 2
            }
        }
    ]

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        width: parent.width - 30
        height: parent.height

        Image {
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            fillMode: Image.PreserveAspectFit
            source: "images/shortwave.svg"
        }

        Label {
            Layout.fillWidth: true
            Layout.topMargin: 5

            textFormat: Text.MarkdownText
            text: qsTr(`
## About
---
**YuRadio** is a cross-platform application built with Qt.
Application uses RadioBrowser API (see <a href="https://api.radio-browser.info/"><font color="${Material.color(Material.Blue)}">radiobrowser</font></a>)
Since this is a public API, some radio stations may have inappropriate content, so be aware!
<br/>
#### MediaPlayer
In Android, it uses built-in _**ExoPlayer**_ for audio playback.

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
