import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

import "radiobrowser.mjs" as RadioBrowser
import network

ItemDelegate {
    id: root

    required property int index
    required property string favicon
    required property string name
    required property string tags
    required property string url_resolved
    required property string countrycode
    required property string stationuuid
    required property int bitrate
    required property NetworkManager networkManager

    property bool currentStation: MainRadioPlayer.currentItem?.stationuuid == stationuuid

    Binding {
        when: root.currentStation
        target: root.background
        property: "color"
        value: Qt.color("lightsteelblue").darker(AppSettings.isDarkTheme ? 1.8 : 1.05)
    }

    height: GridView.view.cellHeight
    width: GridView.view.cellWidth

    RowLayout {
        anchors.fill: parent

        RadioImage {
            id: radioImage

            fallbackSource: AppSettings.isDarkTheme ? "images/radio-white.png" : "images/radio.png"
            targetSource: root.favicon

            Layout.fillHeight: true
            Layout.leftMargin: 5
            Layout.topMargin: 5
            Layout.bottomMargin: 5
            Layout.preferredWidth: height

            fillMode: Image.PreserveAspectFit
            smooth: true

            IconImage {
                anchors {
                    left: parent.left
                    top: parent.top
                    leftMargin: 5
                    topMargin: 5
                }

                opacity: 0.8
                source: root.countrycode ? `https://flagsapi.com/${root.countrycode}/flat/24.png` : ''
                sourceSize: Qt.size(24, 24)
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: 5
            Layout.rightMargin: 5

            Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.name ? root.name : "Unknown Station"
                font.bold: true
                font.pointSize: 15
            }

            Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.tags
                font.pointSize: 14
            }
        }

        IconButton {
            id: moreOptions
            focus: true

            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            implicitWidth: 64

            icon.fillMode: Image.PreserveAspectFit
            icon.source: "images/more-vert.svg"
            icon.sourceSize: Qt.size(32, 32)
            focusPolicy: Qt.StrongFocus

            onClicked: {
                moreOptionsMenu.popup(moreOptions);
            }
        }
    }

    Label {
        text: qsTr("%1 kbps").arg(root.bitrate)
        font.pointSize: 8
        opacity: 0.8

        anchors {
            bottom: parent.bottom
            right: parent.right
            rightMargin: 10
            bottomMargin: 5
        }
    }

    Menu {
        id: moreOptionsMenu

        property bool bookmarkAdded
        property bool canVote

        onAboutToShow: {
            bookmarkAdded = Storage.existsBookmark(root.stationuuid);
            canVote = !Storage.existsVote(root.stationuuid);
        }

        EnhancedMenuItem {
            text: moreOptionsMenu.bookmarkAdded ? qsTr("Delete bookmark") : qsTr("Add bookmark")
            icon.source: moreOptionsMenu.bookmarkAdded ? "images/bookmark-added.svg" : "images/bookmark.svg"
            onTriggered: {
                if (moreOptionsMenu.bookmarkAdded) {
                    Storage.deleteBookmark(root.stationuuid);
                } else {
                    Storage.addBookmark(root.GridView.view.model.get(root.index));
                }
            }
        }

        EnhancedMenuItem {
            text: moreOptionsMenu.canVote ? qsTr("Vote") : qsTr("Already Voted")
            icon.source: moreOptionsMenu.canVote ? "images/thumb-up.svg" : "images/thumb-up-filled.svg"
            enabled: moreOptionsMenu.canVote
            onTriggered: {
                if (moreOptionsMenu.canVote) {
                    Storage.addVote(root.stationuuid);
                    RadioBrowser.vote(root.networkManager.baseUrl, root.stationuuid);
                }
            }
        }
    }

    component EnhancedMenuItem: MenuItem {
        focusPolicy: Qt.TabFocus
    }
}
