pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtNetwork
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "radiobrowser.mjs" as RadioBrowser
import network
import Main
import YuRadioContents

ApplicationWindow {
    id: root

    readonly property bool isDesktopLayout: width >= AppConfig.portraitLayoutWidth
    property list<Item> loadedPages
    property bool isBottomBarDetached: root.width > AppConfig.detachBottomBarWidth

    function stackViewPushPage(component: Component, objectName: string): void {
        if (mainStackView.currentItem?.objectName == objectName) {
            return;
        }
        if (mainStackView.depth > 1) {
            mainStackView.popToIndex(0);
        }
        let loadedPage = loadedPages.find(item => item.objectName == objectName);
        if (loadedPage) {
            if (mainStackView.currentItem.objectName !== loadedPage.objectName) {
                mainStackView.replaceCurrentItem(loadedPage);
            }
        } else {
            loadedPage = component.createObject(root);
            loadedPages.push(loadedPage);
            mainStackView.replaceCurrentItem(loadedPage);
        }
    }

    function backButtonPressed() {
        if (mainStackView.depth > 1) {
            mainStackView.popCurrentItem();
        } else {
            Qt.quit();
        }
    }

    width: 640
    height: 880
    minimumWidth: AppConfig.minimumWindowWidth
    minimumHeight: AppConfig.minimumWindowHeight

    title: qsTr("YuRadio")
    visible: true

    Material.theme: AppConfig.isDarkTheme ? Material.Dark : Material.Light

    Component.onCompleted: {
        AppStorage.init();
    }

    Settings {
        property alias windowX: root.x
        property alias windowY: root.y
        property alias windowWidth: root.width
        property alias windowHeight: root.height
        property alias windowVisibility: root.visibility
    }

    StateGroup {
        states: [
            State {
                when: MainRadioPlayer.currentItem.isValid() && root.isBottomBarDetached

                StateChangeScript {
                    script: radioStationInfoPanel.open()
                }
            },
            State {
                when: !MainRadioPlayer.currentItem.isValid() || !root.isBottomBarDetached

                StateChangeScript {
                    script: radioStationInfoPanel.close()
                }
            }
        ]
    }

    NetworkManager {
        id: networkManager

        baseUrl: AppSettings.radioBrowserBaseUrl

        Component.onCompleted: {
            if (!AppSettings.radioBrowserBaseUrl) {
                RadioBrowser.baseUrlRandom().then(url => {
                    AppSettings.radioBrowserBaseUrl = url;
                });
            } else {
                RadioBrowser.getStation(baseUrl, AppSettings.stationUuid).then(station => {
                    let parsedItem = RadioStationFactory.fromJson(station);
                    MainRadioPlayer.currentItem = parsedItem;
                });
            }
        }

        onBaseUrlChanged: {
            if (baseUrl) {
                if (!Storage.getCountries().length) {
                    console.log("Caching countries...");
                    RadioBrowser.getCountries(baseUrl).then(countries => {
                        Storage.addCountries(countries.filter(country => country.name && country.iso_3166_1).map(country => country.name));
                        console.log("Countries Cached!");
                    });
                }
                if (!Storage.getLanguages().length) {
                    console.log("Caching languages...");
                    RadioBrowser.getLanguages(baseUrl).then(languages => {
                        Storage.addLanguages(languages.filter(language => language.name && language.iso_639).map(language => language.name));
                        console.log("Languages Cached!");
                    });
                }
                if (!Storage.getTags().length) {
                    console.log("Caching tags...");
                    RadioBrowser.getTopUsedTags(baseUrl, 100).then(tags => {
                        Storage.addTags(tags.filter(tag => tag.name).map(tag => tag.name));
                        console.log("Tags Cached!");
                    });
                }
            }
        }
    }

    RadioDrawer {
        id: drawer

        isDesktopLayout: root.isDesktopLayout

        onShowSearchRequested: {
            root.stackViewPushPage(searchPage, "searchPage");
        }
        onShowBookmarksRequested: {
            root.stackViewPushPage(bookmarkPage, "bookmarkPage");
        }
        onShowHistoryRequested: {
            root.stackViewPushPage(historyPage, "historyPage");
        }
        onShowSettingsRequested: {
            root.stackViewPushPage(settingsPage, "settingsPage");
        }
        onShowAboutRequested: {
            root.stackViewPushPage(aboutPage, "aboutPage");
        }
    }

    LanguageTranslator {
        id: languageTranslator

        Component.onCompleted: {
            if (!AppSettings.locale) {
                if (loadSystemLanguage()) {
                    AppSettings.locale = Qt.locale().name;
                } else {
                    load("en_US");
                    AppSettings.locale = "en_US";
                }
            } else {
                load(AppSettings.locale);
            }
        }
    }

    MusicInfoModel {
        id: musicInfoModel
    }

    Component {
        id: locationPage

        RadioStationLocationPage {
            stationLatitude: radioStationInfoPanel.stationLatitude
            stationLongitude: radioStationInfoPanel.stationLongitude
        }
    }

    RadioStationInfoPanel {
        id: radioStationInfoPanel

        property real stationLatitude
        property real stationLongitude

        musicInfoModel: musicInfoModel

        onShowRadioStationLocationRequested: (stationLat, stationLong) => {
            stationLatitude = stationLat;
            stationLongitude = stationLong;
            mainStackView.push(locationPage);
        }
    }

    StackView {
        id: mainStackView

        anchors {
            left: parent.left
            right: parent.right
            leftMargin: drawer.modal ? 0 : drawer.width * drawer.position
            rightMargin: radioStationInfoPanel.width * radioStationInfoPanel.position

            top: parent.top
            bottom: androidKeyboardRectangleLoader.top
        }

        focus: true
        Component.onCompleted: {
            if (AppSettings.startPage === "search") {
                root.stackViewPushPage(searchPage, "searchPage");
            } else if (AppSettings.startPage === "bookmark") {
                root.stackViewPushPage(bookmarkPage, "bookmarkPage");
            } else if (AppSettings.startPage === "history") {
                root.stackViewPushPage(historyPage, "historyPage");
            } else {
                root.stackViewPushPage(searchPage, "searchPage");
            }
        }

        Component {
            id: searchPage

            SearchPage {
                objectName: "searchPage"

                isDesktopLayout: root.isDesktopLayout
                drawer: drawer
                networkManager: networkManager
                musicInfoModel: musicInfoModel
                stationInfoPanel: radioStationInfoPanel
            }
        }

        Component {
            id: bookmarkPage

            BookmarkPage {
                objectName: "bookmarkPage"

                drawer: drawer
                isDesktopLayout: root.isDesktopLayout
                networkManager: networkManager
                musicInfoModel: musicInfoModel
                stationInfoPanel: radioStationInfoPanel
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

    Loader {
        id: androidKeyboardRectangleLoader

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        active: Qt.platform.os === "android"
        sourceComponent: Item {
            height: AndroidKeyboard?.height / Screen.devicePixelRatio
        }
    }

    header: ToolBar {
        id: headerToolBar

        Material.background: AppConfig.isDarkTheme ? root.Material.background.lighter(1.5) : root.Material.primary

        RowLayout {
            anchors.fill: parent

            Item {
                id: headerSpacer

                implicitWidth: drawer.modal ? 0 : drawer.width * drawer.position
            }

            ToolButton {
                id: backButton

                Accessible.name: mainStackView.depth > 1 ? qsTr("Back") : qsTr("Menu")

                action: navigateAction
                Material.foreground: Material.color(Material.Grey, Material.Shade100)
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true

                sourceComponent: mainStackView.currentItem?.headerContent
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
        running: AppSettings.sleepInterval > 0
        onTriggered: {
            MainRadioPlayer.stop()
        }
    }

    Connections {
        target: NetworkInformation

        enabled: MainRadioPlayer.currentItem.isValid() && AppSettings.resumePlaybackWhenNetworkRestored && MainRadioPlayer.playbackState !== RadioPlayer.PausedState

        function onReachabilityChanged() {
            if (NetworkInformation.reachability === NetworkInformation.Reachability.Online) {
                Qt.callLater(MainRadioPlayer.play);
            }
        }
    }
}
