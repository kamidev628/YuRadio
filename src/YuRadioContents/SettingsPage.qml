pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import "radiobrowser.mjs" as RadioBrowser

import YuRadioContents
import network
import Main

Item {
    id: root

    required property NetworkManager networkManager
    required property LanguageTranslator languageTranslator

    focus: true

    ScrollView {
        anchors.fill: parent
        anchors.topMargin: 10
        anchors.leftMargin: 15
        anchors.rightMargin: 5

        contentWidth: -1
        contentHeight: columnLayout.implicitHeight

        ColumnLayout {
            id: columnLayout
            width: parent.width

            Label {
                text: qsTr("Servers")
                font.pointSize: 14
            }

            Rectangle {
                color: Material.foreground
                implicitWidth: parent.width * 2 / 3
                implicitHeight: 1
            }

            Label {
                text: qsTr("Could not fetch available servers")
                Layout.topMargin: 5

                Material.foreground: Material.color(Material.Grey, Material.Shade500)
                opacity: 0.5
                visible: !serversListView.model || !serversListView.model.length
            }

            ListView {
                id: serversListView
                Layout.fillWidth: true
                implicitHeight: 200
                boundsBehavior: Flickable.StopAtBounds

                ButtonGroup {
                    id: buttonGroup
                    onCheckedButtonChanged: {
                        if (root.networkManager.baseUrl != checkedButton.modelData) {
                            AppSettings.radioBrowserBaseUrl = checkedButton.modelData;
                            root.networkManager.baseUrl = checkedButton.modelData;
                        }
                    }
                }
                delegate: ItemDelegate {
                    required property string modelData

                    implicitWidth: ListView.view.width * 2 / 3
                    text: modelData
                    checkable: true
                    checked: modelData == root.networkManager.baseUrl
                    down: checked
                    autoExclusive: true
                    ButtonGroup.group: buttonGroup
                }

                Component.onCompleted: {
                    RadioBrowser.baseUrls().then(urls => {
                        model = [...new Set(urls)];
                    });
                }
            }

            Label {
                text: qsTr("Initial Page")
                Layout.topMargin: 20
                font.pointSize: 14
            }

            ComboBox {
                implicitWidth: parent.width * 2 / 3
                model: [
                    {
                        text: qsTr("Search"),
                        page: App.Page.Search
                    },
                    {
                        text: qsTr("Bookmarks"),
                        page: App.Page.Bookmark
                    }
                ]
                textRole: "text"

                Component.onCompleted: {
                    currentIndex = model.findIndex(x => x.page == AppSettings.initialPage);
                }
                onActivated: {
                    AppSettings.initialPage = currentValue.page;
                }
            }

            Label {
                text: qsTr("Language")
                Layout.topMargin: 20
                font.pointSize: 14
            }

            ComboBox {
                implicitWidth: parent.width * 2 / 3
                textRole: "text"

                Component.onCompleted: {
                    model = root.languageTranslator.locales().map(locale => ({
                                text: Qt.locale(locale).nativeLanguageName + (locale.includes("_") ? Qt.locale(locale).nativeTerritoryName : ""),
                                code: locale
                            }));
                    currentIndex = model.findIndex(x => x.code == AppSettings.locale);
                    if (currentIndex == -1) {
                        currentIndex = model.findIndex(x => x.code.includes(AppSettings.locale) || AppSettings.locale.includes(x.code));
                    }
                }
                onActivated: {
                    AppSettings.locale = currentValue.code;
                    root.languageTranslator.load(currentValue.code);
                }
            }

            CheckBox {
                Layout.topMargin: 10

                text: qsTr("Enable Selection Animations")
                checked: AppSettings.enableSelectionAnimation
                onCheckedChanged: {
                    AppSettings.enableSelectionAnimation = checked;
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
