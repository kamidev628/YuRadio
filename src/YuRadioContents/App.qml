pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "radiobrowser.mjs" as RadioBrowser
import network
import Main

ApplicationWindow {
    id: root
    visible: true

    width: 640
    height: 880

    minimumWidth: 300
    minimumHeight: 300

    Material.theme: AppSettings.isDarkTheme ? Material.Dark : Material.Light

    title: qsTr("YuRadio")

    readonly property bool isDesktopLayout: width >= AppSettings.portraitLayoutWidth

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

    enum Page {
        Search,
        Bookmark
    }

    property var loadedPages: []

    function backButtonPressed(event) {
        if (mainStackView.depth > 1) {
            mainStackView.popCurrentItem();
            if (event)
                event.accepted = true;
        } else {
            if (event)
                event.accepted = false;
        }
    }

    function stackViewPushPage(component: Component, objectName: string) {
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

    Component.onCompleted: {
        Storage.init();
        MainRadioPlayer.currentItem = AppSettings.lastStation;
    }

    NetworkManager {
        id: networkManager

        baseUrl: AppSettings.radioBrowserBaseUrl

        Component.onCompleted: {
            if (!AppSettings.radioBrowserBaseUrl) {
                RadioBrowser.baseUrlRandom().then(url => {
                    AppSettings.radioBrowserBaseUrl = url;
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

        Keys.onBackPressed: event => root.backButtonPressed(event)
    }

    header: ToolBar {
        id: headerToolBar

        Material.background: Material.primary
        Binding {
            when: AppSettings.isDarkTheme
            headerToolBar.Material.background: root.Material.background.lighter(1.5)
        }

        RowLayout {
            anchors.fill: parent

            Item {
                id: headerSpacer
            }

            ToolButton {
                id: menuButton
                visible: !backButton.visible
                icon.source: "images/menu.svg"
                Material.foreground: Material.color(Material.Grey, Material.Shade100)
                onClicked: {
                    if (drawer.opened) {
                        drawer.close();
                    } else {
                        drawer.open();
                    }
                }
            }

            ToolButton {
                id: backButton
                visible: mainStackView.currentItem?.displayBackButton ?? false
                icon.source: "images/arrow-back.svg"
                Material.foreground: Material.color(Material.Grey, Material.Shade100)
                onClicked: root.backButtonPressed()
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: mainStackView.currentItem?.headerContent
            }
        }

        Keys.forwardTo: [mainStackView]
    }

    Shortcut {
        sequences: ["Media Play", "Media Pause", "Toggle Media Play/Pause", "Media Stop"]
        context: Qt.ApplicationShortcut
        enabled: {
          if (AppSettings.isMobile) {
            return false;
          }
          return !mediaPlayGlobalShortcut.enabled
        } 
        onActivated: {
            MainRadioPlayer.toggle();
        }
    }

    GlobalShortcut {
      id: mediaPlayGlobalShortcut
      sequence: "Media Play"
      onActivated: {
          MainRadioPlayer.toggle();
      }
    }
}
