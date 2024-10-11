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

    function desiredWidth(maxWidth: real): real {
        return AppConfig.isSmallSize(root.width) ? maxWidth : Math.min(500, maxWidth * 2 / 3);
    }

    contentWidth: -1
    contentHeight: generalPage.implicitHeight

    Binding {
        target: root.contentItem
        property: "boundsBehavior"
        value: Flickable.StopAtBounds
    }

    Item {
        id: generalPage

        implicitHeight: columnLayout.implicitHeight
        implicitWidth: parent.width

        ColumnLayout {
            id: columnLayout

            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
                topMargin: 20
            }

            ScalableLabel {
                text: qsTr("Available Servers")
                Layout.fillWidth: true
            }

            Rectangle {
                implicitWidth: root.desiredWidth(parent.width)
                implicitHeight: 1

                color: Material.foreground
            }

            ListView {
                id: serversListView

                Layout.fillWidth: true
                Layout.preferredHeight: 150

                clip: true
                focus: true

                boundsBehavior: Flickable.StopAtBounds

                delegate: ScalableItemDelegate {
                    required property string modelData

                    focus: true
                    focusPolicy: Qt.StrongFocus

                    implicitWidth: root.desiredWidth(ListView.view.width)
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
                id: startPageLabel

                Layout.topMargin: 20
                Layout.fillWidth: true

                text: qsTr("Start Page")
            }

            ScalableComboBox {
                implicitWidth: root.desiredWidth(parent.width)

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
            }

            ScalableComboBox {
                implicitWidth: root.desiredWidth(parent.width)

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
            }

            ScalableComboBox {
                implicitWidth: root.desiredWidth(parent.width)

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

                text: qsTr("Resume playback when back online")
                checked: AppSettings.resumePlaybackWhenNetworkRestored
                onCheckedChanged: {
                    AppSettings.resumePlaybackWhenNetworkRestored = checked;
                }
            }

            ScalableCheckBox {
                id: sleepTimerCheckBox

                Layout.topMargin: 5
                Layout.fillWidth: true

                checked: AppSettings.sleepInterval > 0
                text: qsTr("Enable sleep timer")

                onClicked: {
                    if (!checked) {
                        AppSettings.sleepInterval = -1;
                    } else {}
                }

                Connections {
                    target: AppSettings

                    function onSleepIntervalChanged() {
                        if (AppSettings.sleepInterval === -1) {
                            sleepTimerCheckBox.checked = false;
                        }
                    }
                }
            }

            SpotifyButton {
                id: spotifyButton

                property bool shouldShowMessage: false

                Layout.topMargin: 10
                implicitWidth: root.desiredWidth(parent.width)

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
        }
        anchors.centerIn: Overlay.overlay
        standardButtons: Dialog.Ok
    }
}
