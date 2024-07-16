import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

import Main

/*
 * List of radio stations: https://dir.xiph.org/yp.xml
 *
 */

ApplicationWindow {
    id: root
    visible: true

    width: 640
    height: 980

    Material.theme: AppSettings.isDarkTheme ? Material.Dark : Material.Light

    title: qsTr("YuRadio")

    RadioDrawer {
        id: drawer
    }

    StackView {
        id: mainStackView
        initialItem: mainView
        anchors.fill: parent

        Component {
            id: mainView

            RadioStationsView {
                anchors.fill: parent

                mainDrawer: drawer
            }
        }
    }

    header: mainStackView.currentItem?.header ?? null
}
