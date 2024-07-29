pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Material

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

    function backButtonPressed(event) {
        if (mainStackView.depth > 1) {
            mainStackView.pop();
            event.accepted = true;
        } else {
            event.accepted = false;
        }
    }

    RadioDrawer {
        id: drawer

        onShowBookmarksRequested: {
            if (mainStackView.currentItem.objectName != "favoriteView") {
                mainStackView.push(favoriteView);
            }
        }
        onShowSearchRequested: {
            if (mainStackView.currentItem.objectName != "mainView") {
                mainStackView.push(mainView);
            }
        }
    }

    StackView {
        id: mainStackView
        initialItem: favoriteView
        anchors.fill: parent
        focus: true

        Component {
            id: mainView

            RadioStationsView {
                objectName: "mainView"
                mainDrawer: drawer
            }
        }

        Component {
            id: favoriteView
            FavoriteRadioStationsView {
                objectName: "favoriteView"
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
