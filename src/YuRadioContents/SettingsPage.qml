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

            ScalableLabel {
                text: qsTr("Available Servers")
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

                delegate: ScalableItemDelegate {
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

                ScalableLabel {
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

            ScalableLabel {
                Layout.topMargin: 20

                text: qsTr("Start Page")
            }

            ScalableComboBox {
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

            ScalableLabel {
                Layout.topMargin: 20

                text: qsTr("Language")
            }

            ScalableComboBox {
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

            ScalableCheckBox {
                Layout.topMargin: 10

                text: qsTr("Animate selection changes")
                checked: AppSettings.enableSelectionAnimation
                onCheckedChanged: {
                    AppSettings.enableSelectionAnimation = checked;
                }
            }

            ScalableCheckBox {
                id: showTrayIconCheckbox

                Layout.topMargin: 5

                text: qsTr("Show icon in tray")
                checked: AppSettings.showIconInTray
                visible: AppConfig.trayIconAvailable
                onCheckedChanged: {
                    AppSettings.showIconInTray = checked;
                }
            }

            ScalableCheckBox {
                id: showMessagesInTrayCheckbox

                Layout.topMargin: 5

                text: qsTr("Show messages in tray")
                enabled: showTrayIconCheckbox.checked
                checked: AppSettings.showMessagesInTray
                visible: AppConfig.trayIconAvailable
                onCheckedChanged: {
                    AppSettings.showMessagesInTray = checked;
                }
            }

            ScalableCheckBox {
                Layout.topMargin: 5

                text: qsTr("Resume playback when the network connections is restored")
                checked: AppSettings.resumePlaybackWhenNetworkRestored
                onCheckedChanged: {
                    AppSettings.resumePlaybackWhenNetworkRestored = checked;
                }
            }

            Label {
                text: qsTr("Font Scale: %1").arg(slider.value)
                font.pointSize: 12
            }

            RowLayout {
                Layout.fillWidth: true

                spacing: 12

                Label {
                    text: qsTr("A")
                    font.pixelSize: 14
                    font.weight: 400
                }

                Slider {
                    id: slider

                    Layout.fillWidth: true

                    snapMode: Slider.SnapAlways
                    stepSize: 0.1
                    from: 0.8
                    value: AppSettings.fontScale
                    to: 1.5

                    onMoved: AppSettings.fontScale = value
                }

                Label {
                    text: qsTr("A")
                    font.pixelSize: 21
                    font.weight: 400
                }
            }

            SpotifyButton {
                id: spotifyButton

                property bool shouldShowMessage: false

                Layout.topMargin: 10

                text: qsTr("Spotify integration")
                onClicked: {
                    shouldShowMessage = true;
                    root.musicInfoModel.grantSpotifyAccess();
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            Connections {
                target: root.musicInfoModel
                enabled: spotifyButton.shouldShowMessage

                function onSpotifyAccessGranted() {
                    messageDialog.open();
                    spotifyButton.shouldShowMessage = false;
                }
            }
        }
    }

    component ScalableCheckBox: CheckBox {
        ScalableFontPicker {}
    }

    Dialog {
        id: messageDialog

        ScalableLabel {
            text: qsTr("Successfully Authorized")
        }
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok
    }
}
