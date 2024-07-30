import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

import "radiobrowser.mjs" as RadioBrowser

ItemDelegate {
    id: root

    required property int index
    required property string favicon
    required property string name
    required property string tags
    required property string url_resolved
    required property string countrycode
    required property string stationuuid

    width: ListView.view.width

    implicitHeight: 100

    RowLayout {
        anchors.fill: parent

        Image {
            id: radioImage

            Layout.fillHeight: true
            Layout.leftMargin: 5
            Layout.topMargin: 5
            Layout.bottomMargin: 5
            Layout.preferredWidth: height

            Material.foreground: Material.Red
            Material.background: Material.Red

            fillMode: Image.PreserveAspectFit
            source: root.favicon ? root.favicon : (AppSettings.isDarkTheme ? "images/radio-white.png" : "images/radio.png")
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

            Layout.alignment: Qt.AlignVCenter
            Layout.fillHeight: true
            implicitWidth: 64

            icon.fillMode: Image.PreserveAspectFit
            icon.source: "images/more-vert.svg"
            icon.sourceSize: Qt.size(32, 32)
            onClicked: {
                moreOptionsMenu.popup(moreOptions);
            }
        }
    }

    Menu {
        id: moreOptionsMenu

        property bool bookmarkAdded

        onAboutToShow: {
            bookmarkAdded = Storage.existsBookmark(root.stationuuid);
        }

        EnhancedMenuItem {
            text: moreOptionsMenu.bookmarkAdded ? "Delete bookmark" : "Add bookmark"
            icon.source: moreOptionsMenu.bookmarkAdded ? "images/bookmark-added.svg" : "images/bookmark.svg"
            onTriggered: {
                if (moreOptionsMenu.bookmarkAdded) {
                    Storage.deleteBookmark(root.stationuuid);
                } else {
                    Storage.addBookmark(root.ListView.view.model.get(root.index));
                }
            }
        }

        EnhancedMenuItem {
            text: "Vote"
            icon.source: "images/thumb-up.svg"
            onTriggered: {
                RadioBrowser.vote(root.stationuuid);
            }
        }
    }

    component EnhancedMenuItem: MenuItem {
        focusPolicy: Qt.TabFocus
    }
}
