pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import "radiobrowser.mjs" as RadioBrowser

import YuRadioContents
import network
import Main

ScrollView {
    id: root

    required property NetworkManager networkManager
    required property LanguageTranslator languageTranslator
    required property MusicInfoModel musicInfoModel

    property Flickable flickable: contentItem as Flickable

    contentWidth: -1
    contentHeight: generalPage.implicitHeight

    Binding {
        root.flickable.boundsBehavior: Flickable.StopAtBounds
    }

    Item {
        id: generalPage

        implicitHeight: columnLayout.implicitHeight
        implicitWidth: Math.min(parent.width, Math.max(columnLayout.implicitWidth, 500))

        ColumnLayout {
            id: columnLayout

            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
                topMargin: 20
            }

            ScalableLabel {
                Layout.fillWidth: true

                text: qsTr("Available Servers")

                wrapMode: Text.Wrap
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1

                color: Material.foreground
            }

            ListView {
                id: serversListView

                Layout.fillWidth: true
                Layout.preferredHeight: 150
                implicitWidth: contentItem.childrenRect.width

                clip: true
                focus: true

                boundsBehavior: Flickable.StopAtBounds

                delegate: ScalableItemDelegate {
                    required property string modelData

                    width: ListView.view.width

                    focus: true
                    focusPolicy: Qt.StrongFocus

                    Material.foreground: checked ? Material.accent : undefined

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
                    wrapMode: Text.Wrap

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
                id: startPageLabel

                Layout.topMargin: 20
                Layout.fillWidth: true

                text: qsTr("Start Page")
                wrapMode: Text.Wrap
            }

            ScalableComboBox {
                Layout.fillWidth: true
                implicitContentWidthPolicy: ComboBox.WidestText

                model: [
                    {
                        text: qsTr("Search"),
                        page: "search"
                    },
                    {
                        text: qsTr("Bookmarks"),
                        page: "bookmark"
                    },
                    {
                        text: qsTr("History"),
                        page: "history"
                    }
                ]
                textRole: "text"

                Accessible.name: startPageLabel.text
                onActivated: {
                    AppSettings.startPage = currentValue.page;
                }
                Component.onCompleted: {
                    currentIndex = model.findIndex(x => x.page == AppSettings.startPage);
                }
            }

            ScalableLabel {
                id: languageLabel

                Layout.topMargin: 20
                Layout.fillWidth: true

                text: qsTr("Language")
                wrapMode: Text.Wrap
            }

            ScalableComboBox {
                Layout.fillWidth: true

                textRole: "text"
                Accessible.name: languageLabel.text

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

            ScalableLabel {
                id: pauseButtonBehaviourLabel

                Layout.topMargin: 20
                Layout.fillWidth: true

                text: qsTr("Pause button behavior")
                wrapMode: Text.Wrap
            }

            ScalableComboBox {
                Layout.fillWidth: true

                model: [
                    {
                        text: qsTr("Pause"),
                        role: "pause"
                    },
                    {
                        text: qsTr("Stop"),
                        role: "stop"
                    }
                ]
                textRole: "text"

                Accessible.name: pauseButtonBehaviourLabel.text
                Component.onCompleted: {
                    currentIndex = model.findIndex(x => x.role === AppSettings.pauseButtonBehaviour);
                }
                onActivated: {
                    AppSettings.pauseButtonBehaviour = currentValue.role;
                }
            }

            ScalableLabel {
                id: radioStationHeightLabel

                Layout.topMargin: 20
                Layout.fillWidth: true

                text: qsTr("Radio station size")
                wrapMode: Text.Wrap
            }

            ScalableComboBox {
                Layout.fillWidth: true

                model: [
                    {
                        text: qsTr("Small"),
                        role: "small"
                    },
                    {
                        text: qsTr("Medium"),
                        role: "medium"
                    },
                    {
                        text: qsTr("Large"),
                        role: "large"
                    }
                ]
                textRole: "text"

                Accessible.name: radioStationHeightLabel.text
                Component.onCompleted: {
                    currentIndex = model.findIndex(x => x.role === AppSettings.stationDelegateHeightPolicy);
                }
                onActivated: {
                    AppSettings.stationDelegateHeightPolicy = currentValue.role;
                }
            }

            ScalableCheckBox {
                Layout.topMargin: 10
                Layout.fillWidth: true

                text: qsTr("Animate selection changes")
                checked: AppSettings.enableSelectionAnimation
                onCheckedChanged: {
                    AppSettings.enableSelectionAnimation = checked;
                }
            }

            ScalableCheckBox {
                Layout.topMargin: 5
                Layout.fillWidth: true

                text: qsTr("Enable bottom bar blur")
                checked: AppSettings.enableBottomBarBlur
                onCheckedChanged: {
                    AppSettings.enableBottomBarBlur = checked;
                }
            }

            ScalableCheckBox {
                Layout.topMargin: 5
                Layout.fillWidth: true

                text: qsTr("Enable infinite text scrolling")

                checked: AppSettings.enableTextScrolling
                onCheckedChanged: {
                    AppSettings.enableTextScrolling = checked;
                }
            }

            ScalableCheckBox {
                id: showTrayIconCheckbox

                Layout.topMargin: 5
                Layout.fillWidth: true

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
                Layout.fillWidth: true

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
                Layout.fillWidth: true

                enabled: AppConfig.networkInformationBackendAvailable

                text: qsTr("Resume playback when back online")
                checked: AppSettings.resumePlaybackWhenNetworkRestored
                onCheckedChanged: {
                    AppSettings.resumePlaybackWhenNetworkRestored = checked;
                }
            }

            SpotifyButton {
                id: spotifyButton

                property bool shouldShowMessage: false

                Layout.topMargin: 10
                Layout.fillWidth: true

                text: qsTr("Spotify integration")
                onClicked: {
                    shouldShowMessage = true;
                    root.musicInfoModel.grantSpotifyAccess();
                }
            }

            Item {
                Layout.preferredHeight: 20
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

    Dialog {
        id: messageDialog

        ScalableLabel {
            text: qsTr("Successfully Authorized")
            wrapMode: Text.Wrap
        }
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok
    }
}
