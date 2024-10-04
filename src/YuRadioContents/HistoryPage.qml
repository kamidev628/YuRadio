pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import Qt.labs.qmlmodels

import YuRadioContents
import Main

Item {
    id: root

    property string acceptedInputText
    readonly property HistorySearchFilterDialog searchFilterDialog: searchFilterDialogLoader.item as HistorySearchFilterDialog

    property Component headerContent: RowLayout {
        id: headerLayout

        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
        }

        SearchBar {
            id: searchBar

            availableWidth: Math.min(parent.width * 5 / 9, 300)

            implicitWidth: height
            searchIcon.color: Material.color(Material.Grey, Material.Shade100)

            Layout.fillHeight: true

            searchInput.onAccepted: {
                root.acceptedInputText = searchInput.text;
            }
        }

        ToolButton {
            id: filterIcon

            Accessible.name: qsTr("Search Filters")
            icon.source: 'images/filter.svg'
            icon.color: Material.color(Material.Grey, Material.Shade100)

            onClicked: {
                filterIcon.forceActiveFocus();
                root.openSearchFilterDialog();
            }
        }

        Shortcut {
            sequences: [StandardKey.Find, "Ctrl+E"]
            onActivated: {
                searchBar.activate();
            }
        }
    }

    function openSearchFilterDialog(): void {
        if (searchFilterDialog) {
            searchFilterDialog.open();
        } else {
            searchFilterDialogLoader.active = true;
        }
    }

    Loader {
        id: searchFilterDialogLoader

        anchors.fill: parent

        active: false

        sourceComponent: HistorySearchFilterDialog {
            id: searchFilterDialog

            implicitWidth: Math.min(Overlay.overlay.width * 3 / 4, 500)
            implicitHeight: Overlay.overlay.height * 3 / 4

            anchors.centerIn: Overlay.overlay
        }
        onLoaded: root.searchFilterDialog.open()
    }

    Rectangle {
        anchors.fill: parent

        color: Material.color(Material.Grey, AppConfig.isDarkTheme ? Material.Shade600 : Material.Shade400)

        HorizontalHeaderView {
            id: horizontalHeader

            visible: tableView.rows > 0
            anchors.left: tableView.left
            anchors.top: parent.top

            boundsBehavior: Flickable.StopAtBounds
            resizableColumns: false
            clip: true

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
                return (width - (width * 3 / 7)) / (columns - 1);
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
                id: trackHistoryModel

                queryString: `SELECT track_name, json_object('stationName', station_name, 'stationImageUrl', station_image_url) as station, started_at, ended_at
                FROM track_history
                ${root.acceptedInputText.length > 0 ? `WHERE track_name LIKE '%${Utils.mysql_real_escape_string(root.acceptedInputText).split("").join("%")}%' ESCAPE '\\'` : ""}
                ORDER BY datetime(started_at) DESC`
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

            ScrollBar.vertical: ScrollBar {}
            ScrollBar.horizontal: ScrollBar {}
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

        implicitWidth: delegateLabel.fullTextImplicitWidth + 20
        implicitHeight: delegateLabel.fullTextImplicitHeight + 40

        ElidedTextEdit {
            id: delegateLabel

            fontPointSize: 13
            anchors.fill: parent

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

        implicitWidth: rowLayout.implicitWidth + 50
        implicitHeight: rowLayout.implicitHeight

        RowLayout {
            id: rowLayout

            anchors.fill: parent

            Image {
                source: stationDelegateComponent.stationImageUrl

                fillMode: Image.PreserveAspectFit
                sourceSize: Qt.size(height * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
                smooth: true

                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: parent.height
                Layout.preferredHeight: parent.height - 10
                Layout.minimumWidth: height
            }

            ElidedTextEdit {
                fullText: stationDelegateComponent.stationName
                fontPointSize: 13

                Layout.minimumWidth: fullTextImplicitWidth + 5
                Layout.preferredWidth: Layout.minimumWidth
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft

                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
