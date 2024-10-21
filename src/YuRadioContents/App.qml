pragma ComponentBehavior: Bound

import QtQuick
import QtNetwork
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "radiobrowser.mjs" as RadioBrowser
import network
import Main
import YuRadioContents

YuRadioWindow {
    id: root

    property list<Item> loadedPages
    property bool isBottomBarDetached: root.width > AppConfig.detachBottomBarWidth

    function stackViewPushPage(objectName: string, operation: var): void {
        if (mainStackView.currentItem?.objectName === objectName) {
            return;
        }

        let component = {
          "searchPage": searchPage,
          "bookmarkPage": bookmarkPage,
          "historyPage": historyPage,
          "settingsPage" : settingsPage,
          "aboutPage" : aboutPage
        }[objectName] ?? searchPage

        if (mainStackView.depth > 1) {
            mainStackView.popToIndex(0);
        }
        let loadedPage = loadedPages.find(item => item.objectName === objectName);
        if (loadedPage) {
            if (mainStackView.currentItem.objectName !== loadedPage.objectName) {
                mainStackView.replaceCurrentItem(loadedPage, {}, operation);
            }
        } else {
            /* Synchronously load page */
            const incubator = component.incubateObject(root, {}, Qt.Synchronous);

            /* If not ready wait incubation */
            if (incubator.status !== Component.Ready) {
                incubator.onStatusChanged = status => {
                    if (status === Component.Ready) {
                        loadedPages.push(incubator.object);
                        mainStackView.replaceCurrentItem(incubator.object, {}, operation);
                    }
                };
            } else {
                /* If it ready push immediately */
                loadedPages.push(incubator.object);
                mainStackView.replaceCurrentItem(incubator.object, {}, operation);
            }
        }
    }

    function backButtonPressed() {
        if (mainStackView.depth > 1) {
            mainStackView.popCurrentItem();
        } else {
            Qt.quit();
        }
    }

    Binding {
        target: AppConfig
        property: "isPortraitLayout"
        value: root.width >= AppConfig.portraitLayoutWidth
    }

    width: 640
    height: 880
    minimumWidth: AppConfig.minimumWindowWidth
    minimumHeight: AppConfig.minimumWindowHeight

    title: qsTr("YuRadio")
    visible: true

    Material.theme: AppConfig.isDarkTheme ? Material.Dark : Material.Light

    Component.onCompleted: {
        QmlApplication.applicationLoaded();
        AppStorage.init();

        /* Load translation */
        if (!AppSettings.locale) {
            if (languageTranslator.loadSystemLanguage()) {
                AppSettings.locale = Qt.locale().name;
            } else {
                languageTranslator.load("en_US");
                AppSettings.locale = "en_US";
            }
        } else {
            languageTranslator.load(AppSettings.locale);
        }

        /* Initial page */
        const operation = StackView.Immediate;
        root.stackViewPushPage(AppSettings.startPage, operation)

        /* Set current media item */
        if (!AppSettings.radioBrowserBaseUrl) {
            RadioBrowser.baseUrlRandom().then(url => {
                AppSettings.radioBrowserBaseUrl = url;
            });
        } else {
            RadioBrowser.getStation(networkManager.baseUrl, AppSettings.stationUuid).then(station => {
                let parsedItem = RadioStationFactory.fromJson(station);
                MainRadioPlayer.currentItem = parsedItem;
            });
        }
    }

    StateGroup {
        states: [
            State {
                when: MainRadioPlayer.currentItem.isValid() && root.isBottomBarDetached && radioStationInfoPanelLoader.panel

                StateChangeScript {
                    script: radioStationInfoPanelLoader.panel.open()
                }
            },
            State {
                when: (!MainRadioPlayer.currentItem.isValid() || !root.isBottomBarDetached) && radioStationInfoPanelLoader.panel

                StateChangeScript {
                    script: radioStationInfoPanelLoader.panel.close()
                }
            }
        ]
    }

    NetworkManager {
        id: networkManager

        baseUrl: AppSettings.radioBrowserBaseUrl
    }

    RadioDrawer {
        id: drawer

        onShowSearchRequested: {
            root.stackViewPushPage("searchPage");
        }
        onShowBookmarksRequested: {
            root.stackViewPushPage("bookmarkPage");
        }
        onShowHistoryRequested: {
            root.stackViewPushPage("historyPage");
        }
        onShowSettingsRequested: {
            root.stackViewPushPage("settingsPage");
        }
        onShowAboutRequested: {
            root.stackViewPushPage("aboutPage");
        }
    }

    LanguageTranslator {
        id: languageTranslator
    }

    MusicInfoModel {
        id: musicInfoModel
    }

    Component {
        id: locationPage

        RadioStationLocationPage {
            stationLatitude: radioStationInfoPanelLoader.stationLatitude
            stationLongitude: radioStationInfoPanelLoader.stationLongitude
        }
    }

    Loader {
        id: radioStationInfoPanelLoader

        property RadioStationInfoPanel panel: item as RadioStationInfoPanel

        property real position
        property real stationLatitude
        property real stationLongitude

        active: root.isBottomBarDetached || position > 0

        sourceComponent: RadioStationInfoPanel {
            musicInfoModel: musicInfoModel

            onPositionChanged: {
                radioStationInfoPanelLoader.position = position;
            }

            onShowRadioStationLocationRequested: (stationLat, stationLong) => {
                radioStationInfoPanelLoader.stationLatitude = stationLat;
                radioStationInfoPanelLoader.stationLongitude = stationLong;
                mainStackView.push(locationPage);
            }
        }
    }

    StackView {
        id: mainStackView

        property StackViewPage page: currentItem as StackViewPage

        anchors.fill: parent

        anchors {
            bottomMargin: root.bottomMargin
            leftMargin: drawer.modal ? 0 : drawer.width * drawer.position
            rightMargin: {
                if (radioStationInfoPanelLoader.panel) {
                    return radioStationInfoPanelLoader.panel.width * radioStationInfoPanelLoader.panel.position;
                }
                return 0;
            }
        }

        focus: true

        Component {
            id: searchPage

            SearchPage {
                objectName: "searchPage"

                drawer: drawer
                networkManager: networkManager
                musicInfoModel: musicInfoModel
            }
        }

        Component {
            id: bookmarkPage

            BookmarkPage {
                objectName: "bookmarkPage"

                drawer: drawer
                networkManager: networkManager
                musicInfoModel: musicInfoModel
            }
        }

        Component {
            id: historyPage

            HistoryPage {
                objectName: "historyPage"
            }
        }

        Component {
            id: settingsPage

            SettingsPage {
                objectName: "settingsPage"

                sleepTimerLeftInterval: sleepTimerUpdateInterval.sleepTimerLeftInterval
                audioRecorder: MainRadioPlayer.audioStreamRecorder
                networkManager: networkManager
                languageTranslator: languageTranslator
                musicInfoModel: musicInfoModel
            }
        }

        Component {
            id: aboutPage

            AboutPage {
                objectName: "aboutPage"
            }
        }
    }

    header: ToolBar {
        id: headerToolBar

        property color backgroundColor: root.Material.background

        Material.background: backgroundColor

        Binding {
            target: AppColors
            property: "headerColor"
            value: headerToolBar.backgroundColor
        }

        states: [
            State {
                name: "morphBackground"
                when: mainStackView.page.morphHeaderBackground

                PropertyChanges {
                    headerToolBar.backgroundColor: AppColors.toolBarMorphColor
                }
            }
        ]

        transitions: [
            Transition {
                to: "morphBackground"
                reversible: true

                ColorAnimation {
                    target: headerToolBar
                    property: "backgroundColor"
                    duration: 500
                }
            }
        ]

        RowLayout {
            anchors.fill: parent

            Material.theme: root.Material.theme

            Item {
                id: headerSpacer

                implicitWidth: drawer.modal ? 0 : drawer.width * drawer.position
            }

            ToolButton {
                id: backButton

                text: mainStackView.depth > 1 ? qsTr("Back") : qsTr("Menu")
                icon.color: AppColors.toolButtonColor
                display: AbstractButton.IconOnly

                action: navigateAction
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true

                sourceComponent: mainStackView.page.headerContent
            }

            Item {
                id: headerSpacerRight

                implicitWidth: {
                    if (radioStationInfoPanelLoader.panel) {
                        return radioStationInfoPanelLoader.panel.width * radioStationInfoPanelLoader.panel.position;
                    }
                    return 0;
                }
            }
        }

        Keys.forwardTo: [mainStackView]
    }

    Action {
        id: navigateAction

        icon.source: mainStackView.depth > 1 ? "images/arrow-back.svg" : "images/menu.svg"
        onTriggered: {
            if (mainStackView.depth > 1) {
                mainStackView.popCurrentItem();
            } else {
                drawer.toggle();
            }
        }
    }

    Shortcut {
        sequence: "Esc"
        onActivated: navigateAction.trigger()
    }

    Shortcut {
        sequence: "Back"
        onActivated: root.backButtonPressed()
    }

    Shortcut {
        sequences: ["Media Play", "Media Pause", "Toggle Media Play/Pause", "Media Stop"]
        context: Qt.ApplicationShortcut
        enabled: {
            if (MainRadioPlayer.canHandleMediaKeys) {
                return false;
            }
            return !mediaPlayGlobalShortcut.enabled;
        }
        onActivated: {
            MainRadioPlayer.toggleRadio();
        }
    }

    Loader {
        id: messageDialogLoader

        property Dialog messageDialog: item as Dialog

        property string text
        property string informativeText

        function open() {
            active = true;
        }

        active: false

        sourceComponent: Dialog {
            property alias text: messageDialogText.text
            property alias informativeText: messageDialogInformation.text

            ColumnLayout {
                anchors.fill: parent

                ScalableLabel {
                    id: messageDialogText

                    Layout.fillWidth: true
                    text: messageDialogLoader.text

                    wrapMode: Text.Wrap
                }

                ScalableLabel {
                    id: messageDialogInformation

                    Layout.topMargin: 10
                    Layout.fillWidth: true
                    text: messageDialogLoader.informativeText

                    wrapMode: Text.Wrap
                }
            }
            anchors.centerIn: Overlay.overlay
            standardButtons: Dialog.Ok

            onClosed: messageDialogLoader.active = false
        }

        onLoaded: messageDialog.open()
    }

    GlobalShortcut {
        id: mediaPlayGlobalShortcut

        enabled: !MainRadioPlayer.canHandleMediaKeys
        sequence: "Media Play"
        onActivated: {
            MainRadioPlayer.toggleRadio();
        }
    }

    Loader {
        id: trayIconLoader

        active: AppSettings.showIconInTray && AppConfig.trayIconAvailable
        sourceComponent: TrayIcon {
            window: root
        }
    }

    Timer {
        id: sleepTimer

        interval: AppSettings.sleepInterval
        running: AppSettings.enableSleepTimer && AppSettings.sleepInterval > 0 && MainRadioPlayer.playing

        onIntervalChanged: {
            restart();
        }
        onTriggered: {
            MainRadioPlayer.stop();
            MainRadioPlayer.audioStreamRecorder.stop();
        }
    }

    Timer {
        id: sleepTimerUpdateInterval

        property int sleepTimerLeftInterval: Math.max(0, sleepTimer.interval - sleepTimerElapsed)
        property int sleepTimerElapsed: 0
        property date dateBefore: new Date()

        interval: 1000 /* Update every minute */
        running: sleepTimer.running
        repeat: sleepTimerLeftInterval > 0

        onRunningChanged: {
            if (running) {
                sleepTimerElapsed = 0;
                dateBefore = new Date();
            }
        }

        onTriggered: {
            const currentDate = new Date();
            sleepTimerElapsed += currentDate.getTime() - dateBefore.getTime();
            dateBefore = currentDate;
        }
    }

    Timer {
        id: resumePlaybackTimer

        property int maximumNumberRetries: 10
        property int currentRetry: 0

        interval: 3000
        running: repeat && AppSettings.resumePlaybackWhenNetworkRestored && !MainRadioPlayer.playing && MainRadioPlayer.currentItem.isValid() && MainRadioPlayer.error !== RadioPlayer.NoError && NetworkInformation.reachability === NetworkInformation.Reachability.Online
        repeat: currentRetry < maximumNumberRetries

        onTriggered: {
            MainRadioPlayer.play();
            currentRetry += 1;
            console.log("Reconnection retry:", currentRetry);
        }
    }

    Connections {
        target: MainRadioPlayer

        function onPlayingChanged() {
            if (MainRadioPlayer.playing) {
                resumePlaybackTimer.currentRetry = 0;
            }
        }
    }

    Connections {
        target: MainRadioPlayer.audioStreamRecorder

        function onErrorOccurred() {
            messageDialogLoader.text = "Recording error";
            messageDialogLoader.informativeText = MainRadioPlayer.audioStreamRecorder.errorString;
            messageDialogLoader.open();
        }
    }
}
