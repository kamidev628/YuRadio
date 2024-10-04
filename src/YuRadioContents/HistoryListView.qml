import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import YuRadioContents
import Main

ListView {
    id: root

    property string queryFilters

    function refreshModel() {
        let storedContentY = contentY;
        let yPositionBefore = visibleArea.yPosition;
        let heightRatioBefore = visibleArea.heightRatio;
        queryModel.refresh();
        contentY = yPositionBefore * contentHeight;
    }

    spacing: 10
    reuseItems: true
    currentIndex: -1

    ScrollBar.vertical: ScrollBar {}

    model: SqlQueryModel {
        id: queryModel

        queryString: `SELECT json_object('trackName', track_name, 'stationName', station_name, 'stationImageUrl', station_image_url, 'startedAt', started_at, 'endedAt', ended_at) as track
                FROM track_history
                ${root.queryFilters}
                ORDER BY datetime(started_at) DESC`

        onQueryStringChanged: {
            Qt.callLater(root.refreshModel);
        }
    }

    delegate: RowLayout {
        id: trackDelegate

        required property var display
        readonly property var parsedDisplay: JSON.parse(display)

        readonly property string trackName: parsedDisplay.trackName
        readonly property string stationName: parsedDisplay.stationName
        readonly property string stationImageUrl: parsedDisplay.stationImageUrl
        readonly property date startedAt: new Date(parsedDisplay.startedAt)
        readonly property date endedAt: new Date(parsedDisplay.endedAt)
        readonly property string displayDate: qsTr("%1 - %2").arg(Utils.shortDate(startedAt, Qt.locale(AppSettings.locale))).arg(Utils.shortDate(endedAt, Qt.locale(AppSettings.locale)))

        width: ListView.view.width

        RadioImage {
            id: stationImage

            Layout.leftMargin: 10
            Layout.fillHeight: true

            Layout.preferredWidth: Layout.preferredHeight
            Layout.preferredHeight: columnLayout.height

            fallbackSource: AppConfig.isDarkTheme ? "images/radio-white.png" : "images/radio.png"
            targetSource: trackDelegate.stationImageUrl
            fillMode: Image.PreserveAspectFit

            smooth: true
        }

        ColumnLayout {
            id: columnLayout

            spacing: 0
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.fillWidth: true

            ElidedTextEdit {
                Layout.fillWidth: true

                fullText: trackDelegate.trackName

                fontPointSize: 14
                font.bold: true
            }
            ElidedTextEdit {
                Layout.fillWidth: true

                fullText: trackDelegate.stationName

                fontPointSize: 13
                opacity: 0.7
            }
            ElidedTextEdit {
                Layout.fillWidth: true
                Layout.topMargin: 5

                opacity: 0.9
                fullText: trackDelegate.displayDate
            }
        }
    }
}
