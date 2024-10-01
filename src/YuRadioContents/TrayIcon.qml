import QtQml
import QtQuick

import Qt.labs.platform as Platform
import YuRadioContents

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
            icon.source: "qrc:/qt/qml/YuRadioContents/images/play.svg"
            enabled: !MainRadioPlayer.playing && MainRadioPlayer.currentItem.isValid()
            onTriggered: {
                MainRadioPlayer.play();
            }
        }
        Platform.MenuItem {
            text: qsTr("Pause")
            icon.source: "qrc:/qt/qml/YuRadioContents/images/pause.svg"
            enabled: MainRadioPlayer.playing
            onTriggered: {
                MainRadioPlayer.pause();
            }
        }
        Platform.MenuItem {
            icon.source: "qrc:/qt/qml/YuRadioContents/images/stop.svg"
            text: qsTr("Stop")
            enabled: MainRadioPlayer.loading
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
