import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import YuRadioContents
import Main

Dialog {
    id: root

    signal filtersChanged(string searchByField, date startDate, date endDate)

    Material.roundedScale: Material.NotRounded
    standardButtons: Dialog.Ok | Dialog.Cancel

    onAccepted: {
        internal.prevSelectedStartDate = startDateCombo.selectedDate;
        internal.prevSelectedEndDate = endDateCombo.selectedDate;
        internal.prevSelectedSearchBy = searchByCombo.currentIndex;
        let searchByField = searchByCombo.model.get(searchByCombo.currentIndex).fieldName;
        root.filtersChanged(searchByField, startDateCombo.selectedDate, endDateCombo.selectedDate);
    }

    onRejected: {
        startDateCombo.setDate(internal.prevSelectedStartDate);
        endDateCombo.setDate(internal.prevSelectedEndDate);
        searchByCombo.currentIndex = internal.prevSelectedSearchBy;
    }

    StateGroup {
        states: [
            State {
                name: "scrollView"
                when: columnLayout.implicitHeight > scrollView.height
                PropertyChanges {
                    scrollView.contentHeight: columnLayout.implicitHeight
                    columnLayout.height: undefined
                }
            }
        ]
    }

    Binding {
        when: AppConfig.isDarkTheme
        root.Material.background: root.Material.color(Material.Grey, Material.Shade900)
    }

    ScrollView {
        id: scrollView

        anchors.fill: parent

        contentWidth: -1
        contentHeight: -1

        ColumnLayout {
            id: columnLayout

            width: scrollView.width
            height: scrollView.height

            ScalableLabel {
                text: qsTr("Search Filters")

                Layout.fillWidth: true

                font.bold: true
                fontPointSize: 18
                wrapMode: Text.Wrap
            }

            GridLayout {
                id: gridLayout

                Layout.topMargin: 20
                columns: 2

                states: [
                    State {
                        when: columnLayout.width < 400

                        PropertyChanges {
                            gridLayout.columns: 1

                            startDateLabel.Layout.topMargin: 8
                            endDateLabel.Layout.topMargin: 8

                            searchByCombo.Layout.leftMargin: 0
                            startDateCombo.Layout.leftMargin: 0
                            endDateCombo.Layout.leftMargin: 0
                        }
                    }
                ]

                ScalableLabel {
                    id: searchByLabel

                    Layout.fillWidth: true

                    text: qsTr("Search by")
                    elide: Text.ElideRight
                }

                ScalableComboBox {
                    id: searchByCombo

                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Accessible.name: searchByLabel.text

                    implicitContentWidthPolicy: ComboBox.WidestText

                    currentIndex: 0
                    textRole: "name"

                    model: ListModel {
                        ListElement {
                            name: qsTr("Station name")
                            fieldName: "station_name"
                        }
                        ListElement {
                            name: qsTr("Track name")
                            fieldName: "track_name"
                        }
                    }
                }

                ScalableLabel {
                    id: startDateLabel

                    Layout.fillWidth: true

                    text: qsTr("Start date")
                    elide: Text.ElideRight
                }

                DatePickerComboBox {
                    id: startDateCombo

                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Accessible.name: startDateLabel.text

                    implicitContentWidthPolicy: ComboBox.WidestTextWhenCompleted
                }

                ScalableLabel {
                    id: endDateLabel

                    Layout.fillWidth: true

                    text: qsTr("End date")
                    elide: Text.ElideRight
                }

                DatePickerComboBox {
                    id: endDateCombo

                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Accessible.name: endDateLabel.text

                    implicitContentWidthPolicy: ComboBox.WidestTextWhenCompleted
                }

                Item {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                }
            }
        }
    }

    QtObject {
        id: internal

        property int prevSelectedSearchBy
        property date prevSelectedStartDate: new Date(NaN)
        property date prevSelectedEndDate: new Date(NaN)
    }
}
