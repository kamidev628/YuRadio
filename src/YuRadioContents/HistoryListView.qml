pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import YuRadioContents
import Main

Item {
    id: root

    property bool morphBackground: !listView.atYBeginning

    property string queryFilters
    property string orderByField: "datetime(started_at)"
    property bool descending: true

    property bool sortOrderChangedReason: false

    function refreshModel() {
        let storedContentY = listView.contentY;
        let yPositionBefore = listView.visibleArea.yPosition;
        let heightRatioBefore = listView.visibleArea.heightRatio;
        queryModel.refresh();
        if (!root.sortOrderChangedReason) {
            contentY = yPositionBefore * listView.contentHeight;
        }
        root.sortOrderChangedReason = false;
    }

    implicitWidth: listView.implicitWidth
    implicitHeight: listView.implicitHeight

    ListView {
        id: listView

        anchors.fill: parent

        spacing: 10
        reuseItems: true
        currentIndex: -1

        ScrollBar.vertical: ScrollBar {
            visible: !AppConfig.isMobile
        }

        header: HistoryListViewHeader {
            id: historyListViewHeader

            onOrderByFieldChanged: {
                root.sortOrderChangedReason = true;
                root.orderByField = orderByField;
            }
            onDescendingChanged: {
                root.sortOrderChangedReason = true;
                root.descending = descending;
            }
        }

        headerPositioning: ListView.PullBackHeader

        model: SqlQueryModel {
            id: queryModel

            queryString: `SELECT json_object('trackName', track_name, 'stationName', station_name, 'stationImageUrl', station_image_url, 'startedAt', started_at, 'endedAt', ended_at) as track
                FROM track_history
                ${root.queryFilters}
                ORDER BY ${root.orderByField} ${root.descending ? "DESC" : "ASC"}`

            onQueryStringChanged: {
                Qt.callLater(root.refreshModel);
            }
        }

        delegate: ItemDelegate {
            id: trackDelegate

            required property var model
            readonly property var parsedDisplay: JSON.parse(model.display)

            readonly property string trackName: parsedDisplay.trackName
            readonly property string stationName: parsedDisplay.stationName
            readonly property string stationImageUrl: parsedDisplay.stationImageUrl
            readonly property date startedAt: new Date(parsedDisplay.startedAt)
            readonly property date endedAt: new Date(parsedDisplay.endedAt)
            readonly property string displayDate: qsTr("%1 - %2").arg(Utils.shortDate(startedAt, Qt.locale(AppSettings.locale))).arg(Utils.shortDate(endedAt, Qt.locale(AppSettings.locale)))

            property bool expanded: false

            states: [
                State {
                    name: "expanded"
                    when: trackDelegate.expanded

                    PropertyChanges {
                        trackText.wrapMode: TextInput.Wrap
                        stationNameText.wrapMode: TextInput.Wrap
                        dateRangeText.wrapMode: TextInput.Wrap
                    }
                }
            ]

            Behavior on height {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            height: implicitHeight
            width: ListView.view.width

            topPadding: 5
            bottomPadding: 5

            onClicked: {
                trackDelegate.expanded = !trackDelegate.expanded;
            }

            contentItem: RowLayout {
                id: rowLayout

                RadioImage {
                    id: stationImage

                    Layout.leftMargin: 10

                    Layout.maximumWidth: 100
                    Layout.maximumHeight: 100

                    Layout.preferredWidth: Layout.preferredHeight
                    Layout.preferredHeight: columnLayout.height

                    fallbackSource: AppConfig.isDarkTheme ? "images/radio-white.png" : "images/radio.png"
                    targetSource: trackDelegate.stationImageUrl
                    fillMode: Image.PreserveAspectFit

                    sourceSize: Qt.size(height * Screen.devicePixelRatio, height * Screen.devicePixelRatio)

                    smooth: true
                }

                ColumnLayout {
                    id: columnLayout

                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    Layout.fillWidth: true
                    Layout.rightMargin: 10

                    SelectableText {
                        id: trackText

                        Layout.fillWidth: true

                        text: trackDelegate.trackName

                        fontPointSize: 14
                        font.bold: true
                    }

                    SelectableText {
                        id: stationNameText

                        Layout.fillWidth: true

                        text: trackDelegate.stationName

                        fontPointSize: 13
                        opacity: 0.7
                    }

                    SelectableText {
                        id: dateRangeText

                        Layout.fillWidth: true
                        Layout.topMargin: 5

                        fontPointSize: 12

                        opacity: 0.8
                        text: trackDelegate.displayDate
                    }
                }

                Image {
                    id: expandArrow

                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillHeight: true

                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    fillMode: Image.PreserveAspectFit

                    source: trackDelegate.expanded ? "images/keyboard-arrow-up.svg" : "images/keyboard-arrow-down"
                    sourceSize: Qt.size(width, height)
                    opacity: 0.6
                }
            }
        }
    }
}
