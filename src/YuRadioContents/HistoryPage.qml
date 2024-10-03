pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import YuRadioContents
import Main

Item {
    id: root

    Rectangle {
        anchors.fill: parent

        color: Material.color(Material.Grey, AppConfig.isDarkTheme ? Material.Shade600 : Material.Shade400)

        HorizontalHeaderView {
            id: horizontalHeader

            visible: tableView.rows > 0
            anchors.left: tableView.left
            anchors.top: parent.top

            boundsBehavior: Flickable.StopAtBounds

            delegate: TableDelegate {
                color: Material.background.darker(AppConfig.isDarkTheme ? 1.2 : 0.8)
            }
            model: ListModel {
                ListElement {
                    display: qsTr("Track Name")
                }
                ListElement {
                    display: qsTr("Radio Station")
                }
                ListElement {
                    display: qsTr("Started At")
                }
                ListElement {
                    display: qsTr("Ended At")
                }
            }

            syncView: tableView
            clip: true
        }

        TableView {
            id: tableView

            anchors {
                left: parent.left
                top: horizontalHeader.bottom
                right: parent.right
                bottom: parent.bottom

                topMargin: 1
            }

            clip: true

            alternatingRows: true
            columnSpacing: 0
            rowSpacing: 1
            boundsBehavior: Flickable.StopAtBounds

            columnWidthProvider: column => {
                if (column == 0) {
                    return width * 3 / 7;
                }
                return (width - (width * 3 / 7)) / (columns - 1);
            }

            model: SqlQueryModel {
                id: trackHistoryModel

                queryString: `SELECT track_name, json_object('stationName', station_name,
                             'stationImageUrl', station_image_url) as station, started_at,
                             ended_at
                              FROM track_history
                              ORDER BY datetime(started_at) DESC`
            }

            delegate: Loader {
                id: delegateLoader
                clip: true

                required property var display
                required property int column
                required property int row

                property Component tableDelegate: TableDelegate {
                    display: delegateLoader.display
                    row: delegateLoader.row
                    column: delegateLoader.column
                }
                property Component stationDelegate: StationDelegate {
                    display: delegateLoader.display
                    row: delegateLoader.row
                    column: delegateLoader.column
                }
                property Component dateTableDelegate: DateTableDelegate {
                    display: delegateLoader.display
                    row: delegateLoader.row
                    column: delegateLoader.column
                }

                sourceComponent: {
                    if (column === 1) {
                        return stationDelegate;
                    }
                    if (column === 2 || column === 3) {
                        return dateTableDelegate;
                    }
                    return tableDelegate;
                }
            }

            reuseItems: false
            ScrollBar.vertical: ScrollBar {}
        }
    }

    component AlternatingRectangle: Rectangle {
        required property int row
        required property int column

        color: tableView.alternatingRows && row % 2 !== 0 ? Material.background.lighter(AppConfig.isDarkTheme ? 1.4 : 0.9) : Material.background
    }

    component TableDelegate: AlternatingRectangle {
        id: tableDelegate

        required property var display
        property alias label: delegateLabel

        implicitWidth: delegateLabel.implicitWidth + 50
        implicitHeight: delegateLabel.implicitHeight + 40

        ElidedTextEdit {
            id: delegateLabel

            fontPointSize: 13

            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4

            fullText: tableDelegate.display

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    Timer {
        id: refreshModelTimer

        interval: 500
        running: root.visible && AppStorage.streamTitleHistoryDirty
        repeat: false

        onTriggered: {
            AppStorage.streamTitleHistoryDirty = false;
            trackHistoryModel.refresh();
        }
    }

    component DateTableDelegate: TableDelegate {
        readonly property date currentDate: new Date(display)
        readonly property string displayDate: currentDate.toLocaleDateString(Qt.locale(AppSettings.locale), Locale.ShortFormat) + " " + currentDate.toLocaleTimeString(Qt.locale(AppSettings.locale), Locale.ShortFormat)

        label.fullText: displayDate
    }

    component StationDelegate: AlternatingRectangle {
        id: stationDelegateComponent

        required property var display

        readonly property var parsedDisplay: JSON.parse(display)
        readonly property string stationName: parsedDisplay.stationName
        readonly property url stationImageUrl: parsedDisplay?.stationImageUrl ?? ""

        implicitWidth: rowLayout.implicitWidth

        RowLayout {
            id: rowLayout

            anchors.fill: parent

            Image {
                source: stationDelegateComponent.stationImageUrl

                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(height * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
                smooth: true

                Layout.topMargin: 5
                Layout.bottomMargin: 5
                Layout.preferredWidth: height
                Layout.fillHeight: true
            }

            ElidedTextEdit {
                fullText: stationDelegateComponent.stationName
                fontPointSize: 13

                verticalAlignment: Text.AlignVCenter

                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
