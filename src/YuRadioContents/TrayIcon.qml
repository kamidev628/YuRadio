import QtQml
import QtQuick

import Qt.labs.platform as Platform

Platform.SystemTrayIcon {
    id: root

    required property Window window

    visible: true
    icon.source: "qrc:/qt/qml/YuRadioContents/images/shortwave.svg"

    onActivated: reason => {
        if (reason !== Platform.SystemTrayIcon.Context) {
            window.show();
            window.raise();
            window.requestActivate();
        }
    }

    menu: Platform.Menu {
        Platform.MenuItem {
            text: qsTr("Play")
            enabled: !MainRadioPlayer.playing && MainRadioPlayer.mediaItem.source.toString().length > 0
            onTriggered: {
                MainRadioPlayer.play();
            }
        }
        Platform.MenuItem {
            text: qsTr("Pause")
            enabled: MainRadioPlayer.playing
            onTriggered: {
                MainRadioPlayer.pause();
            }
        }
        Platform.MenuItem {
            text: qsTr("Stop")
            enabled: MainRadioPlayer.mediaItem.source.toString().length > 0
            onTriggered: {
                MainRadioPlayer.stop();
            }
        }
        Platform.MenuSeparator {}
        Platform.MenuItem {
            text: qsTr("Quit")
            onTriggered: Qt.quit()
        }
    }

    property Connections streamTitleConnection: Connections {
        target: MainRadioPlayer
        enabled: AppSettings.showMessagesInTray

        function onStreamTitleChanged() {
            root.showMessage(MainRadioPlayer.streamTitle, MainRadioPlayer.currentItem.name, Platform.SystemTrayIcon.Information, 3000);
        }
    }
}
