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
    required property MusicInfoModel musicInfoModel

    focus: true

    ScrollView {
      anchors {
        fill: parent
        topMargin: 10
        leftMargin: 15
        rightMargin: 5
      }

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
                implicitWidth: parent.width * 2 / 3
                implicitHeight: 1

                color: Material.foreground
            }

            ListView {
                id: serversListView

                Layout.fillWidth: true
                Layout.preferredHeight: 150

                clip: true

                boundsBehavior: Flickable.StopAtBounds

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

                Label {
                    anchors {
                        left: parent.left
                        top: parent.top
                        right: parent.right
                        topMargin: 5
                    }

                    text: qsTr("Could not fetch available servers")

                    Material.foreground: Material.color(Material.Grey, Material.Shade500)
                    opacity: 0.5
                    visible: !serversListView.model || !serversListView.model.length
                }

                ButtonGroup {
                    id: buttonGroup

                    onCheckedButtonChanged: {
                        if (root.networkManager.baseUrl != checkedButton.modelData) {
                            AppSettings.radioBrowserBaseUrl = checkedButton.modelData;
                            root.networkManager.baseUrl = checkedButton.modelData;
                        }
                    }
                }
            }

            Label {
                Layout.topMargin: 20

                text: qsTr("Initial Page")
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

                onActivated: {
                    AppSettings.initialPage = currentValue.page;
                }
                Component.onCompleted: {
                    currentIndex = model.findIndex(x => x.page == AppSettings.initialPage);
                }
            }

            Label {
                Layout.topMargin: 20

                text: qsTr("Language")
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

            SpotifyButton {
                Layout.topMargin: 10

                text: qsTr("Spotify integration")
                onClicked: {
                    root.musicInfoModel.grantSpotifyAccess();
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
