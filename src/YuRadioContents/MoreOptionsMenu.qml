pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import YuRadioContents
import "radiobrowser.mjs" as RadioBrowser
import network
import Main

Menu {
    id: root

    required property NetworkManager networkManager

    property radiostation station
    property string uuid: station.uuid

    property bool enableSynchronization: false
    property bool bookmarkAdded
    property bool canVote

    onAboutToShow: {
        bookmarkAdded = Storage.existsBookmark(root.uuid);
        canVote = !Storage.existsVote(root.uuid);
    }

    component EnhancedMenuItem: MenuItem {
        focusPolicy: Qt.TabFocus

        onImplicitWidthChanged: {
            if (root.contentWidth < implicitWidth) {
                root.contentWidth = implicitWidth;
            }
        }
    }

    EnhancedMenuItem {
        text: root.bookmarkAdded ? qsTr("Delete bookmark") : qsTr("Add bookmark")
        icon.source: root.bookmarkAdded ? "images/bookmark-added.svg" : "images/bookmark.svg"

        onTriggered: {
            if (root.bookmarkAdded) {
                AppStorage.deleteBookmark(root.uuid);
            } else {
                AppStorage.addBookmark(root.station);
            }
        }
    }

    EnhancedMenuItem {
        text: root.canVote ? qsTr("Vote") : qsTr("Already Voted")
        icon.source: root.canVote ? "images/thumb-up.svg" : "images/thumb-up-filled.svg"
        enabled: root.canVote

        onTriggered: {
            if (root.canVote) {
                Storage.addVote(root.uuid);
                RadioBrowser.vote(root.networkManager.baseUrl, root.uuid);
            }
        }
    }

    EnhancedMenuItem {
        text: qsTr("Synchronize")
        icon.source: "images/sync.svg"
        visible: root.enableSynchronization
        height: visible ? implicitHeight : 0

        onTriggered: {
            RadioBrowser.getStation(root.networkManager.baseUrl, root.uuid).then(newStation => {
                let parsedStation = RadioStationFactory.fromJson(newStation);
                AppStorage.deleteBookmark(root.uuid);
                AppStorage.addBookmark(parsedStation);
            });
        }
    }
}
