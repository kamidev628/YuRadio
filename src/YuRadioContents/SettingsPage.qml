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

    property string translatedLanguageString: qsTr("Language")
    property string translatedStartPageString: qsTr("Start Page")
    property string translatedFontScaleString: qsTr("Font scale")

    function desiredWidth(maxWidth: real): real {
        return AppConfig.isSmallSize(root.width) ? maxWidth : Math.min(500, maxWidth * 2 / 3);
    }

    focus: true

    TabBar {
        id: tabBar

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        ScalableTabButton {
            text: qsTr("General")
        }
        ScalableTabButton {
            text: qsTr("Font")
        }
    }

    component ScalableTabButton: TabButton {
        ScalableFontPicker {}
    }

    StackLayout {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            top: tabBar.bottom
        }

        currentIndex: tabBar.currentIndex

        ScrollView {
            id: scroll
            contentWidth: -1
            contentHeight: generalPage.implicitHeight

            Binding {
                target: scroll.contentItem
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
                        Layout.topMargin: 20
                        Layout.fillWidth: true

                        text: root.translatedStartPageString
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

                        Accessible.name: root.translatedStartPageString
                        onActivated: {
                            AppSettings.startPage = currentValue.page;
                        }
                        Component.onCompleted: {
                            currentIndex = model.findIndex(x => x.page == AppSettings.startPage);
                        }
                    }

                    ScalableLabel {
                        Layout.topMargin: 20
                        Layout.fillWidth: true

                        text: root.translatedLanguageString
                    }

                    ScalableComboBox {
                        implicitWidth: root.desiredWidth(parent.width)

                        textRole: "text"
                        Accessible.name: root.translatedLanguageString

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

                        text: qsTr("Pause button behaviour")
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
        }

        Item {
            id: fontPage

            ColumnLayout {
                anchors {
                    fill: parent
                    leftMargin: 15
                    topMargin: 15
                    rightMargin: 15
                }

                Label {
                    Layout.topMargin: 20

                    text: `${root.translatedFontScaleString}: ${slider.value.toFixed(1)}`
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
                        Accessible.name: root.translatedFontScaleString

                        snapMode: Slider.SnapAlways
                        stepSize: 0.1
                        from: 0.7
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

                ScalableLabel {
                    Layout.fillWidth: true
                    text: qsTr("Sample Text")
                }

                Item {
                    Layout.fillHeight: true
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
