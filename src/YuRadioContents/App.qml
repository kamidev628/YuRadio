pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "radiobrowser.mjs" as RadioBrowser
import network
import Main
import YuRadioContents

ApplicationWindow {
    id: root

    enum Page {
        Search,
        Bookmark
    }

    readonly property bool isDesktopLayout: width >= AppConfig.portraitLayoutWidth
    property list<Item> loadedPages

    function stackViewPushPage(component: Component, objectName: string): void {
        if (mainStackView.currentItem?.objectName == objectName) {
            return;
        }
        let loadedPage = loadedPages.find(item => item.objectName == objectName);
        if (loadedPage) {
            mainStackView.replaceCurrentItem(loadedPage);
        } else {
            loadedPage = component.createObject(root);
            loadedPages.push(loadedPage);
            mainStackView.replaceCurrentItem(loadedPage);
        }
    }

    width: 640
    height: 880
    minimumWidth: 300
    minimumHeight: 300

    title: qsTr("YuRadio")
    visible: true

    Material.theme: AppConfig.isDarkTheme ? Material.Dark : Material.Light

    Component.onCompleted: {
        Storage.init();
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
                when: root.isDesktopLayout

                PropertyChanges {
                    mainStackView.width: mainStackView.parent.width - drawer.width * drawer.position
                    headerSpacer.implicitWidth: drawer.width * drawer.position

                    drawer.closePolicy: Popup.NoAutoClose
                    drawer.modal: false
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
                    MainRadioPlayer.currentItem = station;
                });
            }
        }

        onBaseUrlChanged: {
            if (baseUrl) {
                if (!Storage.getCountries().length) {
                    RadioBrowser.getCountries(baseUrl).then(countries => {
                        Storage.addCountries(countries.filter(country => country.name && country.iso_3166_1).map(country => country.name));
                    });
                }
                if (!Storage.getLanguages().length) {
                    RadioBrowser.getLanguages(baseUrl).then(languages => {
                        Storage.addLanguages(languages.filter(language => language.name && language.iso_639).map(language => language.name));
                    });
                }
                if (!Storage.getTags().length) {
                    RadioBrowser.getTopUsedTags(baseUrl, 100).then(tags => {
                        Storage.addTags(tags.filter(tag => tag.name).map(tag => tag.name));
                    });
                }
            }
        }
    }

    RadioDrawer {
        id: drawer

        isDesktopLayout: root.isDesktopLayout

        onShowBookmarksRequested: {
            root.stackViewPushPage(bookmarkPage, "bookmarkPage");
        }
        onShowSearchRequested: {
            root.stackViewPushPage(searchPage, "searchPage");
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

    StackView {
        id: mainStackView

        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        width: parent.width

        focus: true
        Component.onCompleted: {
            if (AppSettings.initialPage == App.Page.Search) {
                root.stackViewPushPage(searchPage, "searchPage");
            } else if (AppSettings.initialPage == App.Page.Bookmark) {
                root.stackViewPushPage(bookmarkPage, "bookmarkPage");
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

    header: ToolBar {
        id: headerToolBar

        Material.background: AppConfig.isDarkTheme ? root.Material.background.lighter(1.5) : root.Material.primary

        RowLayout {
            anchors.fill: parent

            Item {
                id: headerSpacer
            }

            ToolButton {
                id: backButton

                action: navigateBackAction
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
        id: navigateBackAction

        icon.source: mainStackView.depth > 1 ? "images/arrow-back.svg" : "images/menu.svg"
        onTriggered: {
            if (mainStackView.depth > 1) {
                mainStackView.popCurrentItem();
            } else {
                if (drawer.opened) {
                    drawer.close();
                } else {
                    drawer.open();
                }
            }
        }
    }

    Shortcut {
        sequences: ["Esc", "Back"]
        onActivated: navigateBackAction.trigger()
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
            MainRadioPlayer.toggle();
        }
    }

    GlobalShortcut {
        id: mediaPlayGlobalShortcut

        enabled: !MainRadioPlayer.canHandleMediaKeys
        sequence: "Media Play"
        onActivated: {
            MainRadioPlayer.toggle();
        }
    }

    Loader {
        id: trayIconLoader
        active: AppSettings.showIconInTray && AppConfig.trayIconAvailable

        sourceComponent: TrayIcon {
            window: root
        }
    }
}
