pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

import "radiobrowser.mjs" as RadioBrowser
import network

/*
 * List of radio stations: https://dir.xiph.org/yp.xml
 *
 */
ApplicationWindow {
    id: root
    visible: true

    width: 640
    height: 880

    Material.theme: AppSettings.isDarkTheme ? Material.Dark : Material.Light

    title: qsTr("YuRadio")

    property var loadedPages: []

    function backButtonPressed(event) {
        if (mainStackView.depth > 1) {
            mainStackView.popCurrentItem();
            event.accepted = true;
        } else {
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

    NetworkManager {
        id: networkManager

        Component.onCompleted: {
            RadioBrowser.baseUrlRandom().then(url => {
                console.log("RadioBrowser BaseUrl:", url);
                baseUrl = url;
            });
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
    }

    StackView {
        id: mainStackView
        anchors.fill: parent
        focus: true

        Component.onCompleted: {
            root.stackViewPushPage(searchPage, "searchPage");
        }

        Component {
            id: searchPage

            SearchPage {
                objectName: "searchPage"
                mainDrawer: drawer
                mainNetworkManager: networkManager
            }
        }

        Component {
            id: bookmarkPage
            BookmarkPage {
                objectName: "bookmarkPage"
                mainNetworkManager: networkManager
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

            ToolButton {
                id: menuButton
                icon.source: "images/menu.svg"
                Material.foreground: Material.color(Material.Grey, Material.Shade100)
                onClicked: {
                    drawer.open();
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                sourceComponent: mainStackView.currentItem?.headerContent
            }
        }

        Keys.onBackPressed: event => root.backButtonPressed(event)
    }
}
