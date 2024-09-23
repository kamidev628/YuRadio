import QtQuick
import QtQuick.Controls

import YuRadioContents
import "radiobrowser.mjs" as RadioBrowser
import network

Menu {
    id: root

    required property NetworkManager networkManager

    property var station
    property string stationuuid: station?.stationuuid ?? ""

    property bool enableSynchronization: true
    property bool bookmarkAdded
    property bool canVote

    onAboutToShow: {
        bookmarkAdded = Storage.existsBookmark(stationuuid);
        canVote = !Storage.existsVote(stationuuid);
    }

    component EnhancedMenuItem: MenuItem {
        focusPolicy: Qt.TabFocus
    }

    EnhancedMenuItem {
        text: root.bookmarkAdded ? qsTr("Delete bookmark") : qsTr("Add bookmark")
        icon.source: root.bookmarkAdded ? "images/bookmark-added.svg" : "images/bookmark.svg"

        onTriggered: {
            if (root.bookmarkAdded) {
                Storage.deleteBookmark(root.stationuuid);
            } else {
                Storage.addBookmark(root.station);
            }
        }
    }

    EnhancedMenuItem {
        text: root.canVote ? qsTr("Vote") : qsTr("Already Voted")
        icon.source: root.canVote ? "images/thumb-up.svg" : "images/thumb-up-filled.svg"
        enabled: root.canVote

        onTriggered: {
            if (root.canVote) {
                Storage.addVote(root.stationuuid);
                RadioBrowser.vote(root.networkManager.baseUrl, root.stationuuid);
            }
        }
    }

    EnhancedMenuItem {
        text: qsTr("Synchronize")
        icon.source: "images/sync.svg"
        visible: root.enableSynchronization
        height: visible ? implicitHeight : 0

        onTriggered: {
            RadioBrowser.getStation(root.networkManager.baseUrl, root.stationuuid).then(newStation => {
                Storage.deleteBookmark(root.stationuuid);
                Storage.addBookmark(newStation);
            });
        }
    }
}
