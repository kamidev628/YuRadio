pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import Qt.labs.qmlmodels

import YuRadioContents
import Main

Rectangle {
    id: root

    property string queryFilters

    function refreshModel() {
        let storedContentY = tableView.contentY;
        let yPositionBefore = tableView.visibleArea.yPosition;
        let heightRatioBefore = tableView.visibleArea.heightRatio;
        queryModel.refresh();
        tableView.contentY = yPositionBefore * tableView.contentHeight;
    }

    color: Material.color(Material.Grey, AppConfig.isDarkTheme ? Material.Shade600 : Material.Shade400)

    HorizontalHeaderView {
        id: horizontalHeader

        property int selectedIndex: 2
        property bool descending: true
        property string orderByField: headerModel.get(selectedIndex).fieldName

        visible: tableView.rows > 0
        anchors.left: tableView.left
        anchors.top: parent.top

        boundsBehavior: Flickable.StopAtBounds
        resizableColumns: false
        clip: true

        delegate: Button {
            id: headerDelegate

            required property var model
            required property int column

            Material.roundedScale: Material.NotRounded
            leftInset: 0
            bottomInset: 0
            rightInset: 0
            topInset: 0

            implicitHeight: 60

            flat: true

            Binding {
                target: headerDelegate.background
                property: "color"
                value: root.Material.background.darker(AppConfig.isDarkTheme ? 1.2 : 0.8)
            }

            ScalableFontPicker {
                fontPointSize: 14
            }

            font.bold: true
            text: model.display

            icon.source: {
                if (horizontalHeader.selectedIndex === column) {
                    if (horizontalHeader.descending) {
                        return "images/arrow-down.svg";
                    } else {
                        return "images/arrow-up.svg";
                    }
                }
                return "";
            }

            onClicked: {
                if (horizontalHeader.selectedIndex === column) {
                    horizontalHeader.descending = !horizontalHeader.descending;
                } else {
                    horizontalHeader.selectedIndex = column;
                }
            }
        }

        model: ListModel {
            id: headerModel

            ListElement {
                display: qsTr("Track Name")
                fieldName: "track_name"
            }
            ListElement {
                display: qsTr("Radio Station")
                fieldName: "station_name"
            }
            ListElement {
                display: qsTr("Started At")
                fieldName: "datetime(started_at)"
            }
            ListElement {
                display: qsTr("Ended At")
                fieldName: "datetime(ended_at)"
            }
        }

        syncView: tableView
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

        function largeScreenWidthProvider(column) {
            if (column == 0) {
                return width * 3 / 7;
            }
            if (column == 1) {
                return width * 2 / 7;
            }
            return (width - (width * 5 / 7)) / (columns - 2);
        }

        function smallScreenWidthProvider(column) {
            if (column === 0) {
                return 300;
            }
            if (column === 1) {
                return 300;
            }
            return 150;
        }

        columnWidthProvider: (width < AppConfig.portraitLayoutWidth ? smallScreenWidthProvider : largeScreenWidthProvider)

        model: SqlQueryModel {
            id: queryModel

            queryString: `SELECT track_name, json_object('stationName', station_name, 'stationImageUrl', station_image_url) as station, started_at, ended_at
                  FROM track_history
                  ${root.queryFilters}
                  ORDER BY ${horizontalHeader.orderByField} ${horizontalHeader.descending ? "DESC" : "ASC"}`

            onQueryStringChanged: {
                Qt.callLater(root.refreshModel);
            }
        }

        delegate: DelegateChooser {
            DelegateChoice {
                column: 1
                StationDelegate {}
            }

            DelegateChoice {
                column: 2
                DateTableDelegate {}
            }

            DelegateChoice {
                column: 3
                DateTableDelegate {}
            }
            DelegateChoice {
                TableDelegate {}
            }
        }

        ScrollBar.vertical: ScrollBar {
            visible: !AppConfig.isMobile
        }
        ScrollBar.horizontal: ScrollBar {
            visible: !AppConfig.isMobile
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

        implicitWidth: delegateLabel.implicitWidth + 20
        implicitHeight: delegateLabel.implicitHeight + 40

        SelectableText {
            id: delegateLabel

            fontPointSize: 13
            anchors.fill: parent
            anchors.margins: 4

            text: tableDelegate.display

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    component DateTableDelegate: TableDelegate {
        readonly property date currentDate: new Date(display)
        readonly property string displayDate: currentDate.toLocaleDateString(Qt.locale(AppSettings.locale), Locale.ShortFormat) + " " + currentDate.toLocaleTimeString(Qt.locale(AppSettings.locale), Locale.ShortFormat)

        label.text: displayDate
    }

    component StationDelegate: AlternatingRectangle {
        id: stationDelegateComponent

        required property var display

        readonly property var parsedDisplay: JSON.parse(display)
        readonly property string stationName: parsedDisplay.stationName
        readonly property url stationImageUrl: parsedDisplay?.stationImageUrl ?? ""

        implicitWidth: rowLayout.implicitWidth
        implicitHeight: rowLayout.implicitHeight

        RowLayout {
            id: rowLayout

            anchors.fill: parent
            anchors.margins: 4

            Image {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: parent.height
                Layout.preferredHeight: parent.height - 10
                Layout.minimumWidth: height

                source: stationDelegateComponent.stationImageUrl

                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(height * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
                smooth: true
            }

            SelectableText {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: Math.max(implicitWidth, 200)

                text: stationDelegateComponent.stationName
                fontPointSize: 13
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
            }
        }
    }
}
