pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import YuRadioContents
import network
import Main

Item {
    id: root

    required property AudioStreamRecorder audioRecorder
    required property NetworkManager networkManager
    required property LanguageTranslator languageTranslator
    required property MusicInfoModel musicInfoModel
    required property int sleepTimerLeftInterval

    property string translatedFontScaleString: qsTr("Font scale")
    property int currentPageIndex: 0

    property Component headerContent: RowLayout {
        spacing: 0

        Item {
            Layout.fillWidth: true
        }

        ToolButton {
            id: sleepTimerButton

            icon.source: AppSettings.enableSleepTimer ? "images/hourglass-on.svg" : "images/hourglass-off.svg"
            icon.color: AppColors.toolButtonColor
            display: AbstractButton.IconOnly

            text: qsTr("Sleep timer configurations")

            onClicked: {
                sleepTimerPopup.open();
            }
        }
    }

    focus: true

    onVisibleChanged: {
        if (visible) {
            /* FIX: workaround for QTBUG-54260 */
            let indexBefore = tabBar.currentIndex;

            /* Reset indeces */
            swipeView.setCurrentIndex(-1);
            tabBar.setCurrentIndex(-1);

            /* Restore indeces */
            swipeView.setCurrentIndex(indexBefore);
            tabBar.setCurrentIndex(indexBefore);
            let highlightMoveDurationBefore = swipeView.internalListView.highlightMoveDuration;
            swipeView.internalListView.highlightMoveDuration = 0;
            swipeView.internalListView.positionViewAtIndex(indexBefore, ListView.SnapPosition);
            swipeView.internalListView.highlightMoveDuration = highlightMoveDurationBefore;
        }
    }

    SleepTimerPopup {
        id: sleepTimerPopup

        sleepTimerLeftInterval: root.sleepTimerLeftInterval
    }

    TabBar {
        id: tabBar

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }

        currentIndex: swipeView.currentIndex

        ScalableTabButton {
            text: qsTr("General")
        }
        ScalableTabButton {
            text: qsTr("Font")
        }
        ScalableTabButton {
            text: qsTr("Recordings")
        }
    }

    component ScalableTabButton: TabButton {
        ScalableFontPicker {}
    }

    SwipeView {
        id: swipeView

        property ListView internalListView: contentItem as ListView

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            top: tabBar.bottom
        }

        currentIndex: tabBar.currentIndex

        SettingsGeneralPage {
            musicInfoModel: root.musicInfoModel
            networkManager: root.networkManager
            languageTranslator: root.languageTranslator
        }

        SettingsFontPage {}

        SettingsRecordingPage {
            audioRecorder: root.audioRecorder
        }
    }
}
