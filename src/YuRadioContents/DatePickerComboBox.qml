pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import YuRadioContents

ScalableComboBox {
    id: root

    readonly property date selectedDate: internal.selectedDate

    function setDate(d: date) {
        internal.selectedDate = d;
        if (Utils.isDateValid(d)) {
            yearSpinBox.value = d.getFullYear();
            monthCombo.month = d.getMonth();
            calendarListView.updateCurrentIndex();
        }
    }

    signal acceptedDate(date d)

    locale: Qt.locale(AppSettings.locale)
    displayText: Utils.isDateValid(root.selectedDate) ? selectedDate.toLocaleDateString(root.locale, Locale.ShortFormat) : ""
    inputMethodHints: Qt.ImhDate
    editable: false

    popup: Dialog {
        id: datePopup

        function updateResetButton() {
            let resetButton = datePopup.standardButton(Dialog.Reset);
            resetButton.enabled = Utils.isDateValid(root.selectedDate);
        }

        leftMargin: 2
        rightMargin: 2
        topMargin: 2
        bottomMargin: 2

        Material.roundedScale: Material.NotRounded
        standardButtons: Dialog.Ok | Dialog.Cancel | Dialog.Reset

        onAboutToShow: {
            updateResetButton();
        }

        onOpened: {
            /* FIXME: QTBUG-77418. It's marked as closed but it's not actually fixed... */
            calendarListView.highlightRangeMode = ListView.StrictlyEnforceRange;
        }
        onClosed: {
            calendarListView.highlightRangeMode = ListView.NoHighlightRange;
        }

        onAccepted: {
            root.acceptedDate(root.selectedDate);
            internal.prevSelectedDate = internal.selectedDate;
        }

        onRejected: {
            internal.selectedDate = internal.prevSelectedDate;
        }

        onReset: {
            internal.selectedDate = new Date(NaN);
            internal.prevSelectedDate = new Date(NaN);
        }

        contentItem: ColumnLayout {
            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                SpinBox {
                    id: yearSpinBox

                    inputMethodHints: Qt.ImhDigitsOnly
                    from: 1980
                    to: new Date().getFullYear()
                    value: new Date().getFullYear()
                    stepSize: 1
                    editable: true

                    locale: root.locale

                    Layout.minimumHeight: implicitHeight
                    Layout.minimumWidth: implicitWidth

                    background.opacity: 0

                    textFromValue: (value, locale) => {
                        /* FIXME: produces binding loop: Binding loop detected for property "text" */
                        return value;
                    }

                    onValueModified: {
                        calendarListView.updateCurrentIndex();
                    }
                }

                ComboBox {
                    id: monthCombo

                    property int month: currentIndex === -1 ? 0 : currentIndex

                    Layout.minimumHeight: implicitHeight
                    Layout.minimumWidth: implicitWidth
                    implicitContentWidthPolicy: ComboBox.WidestText

                    background.opacity: 0
                    currentIndex: new Date().getMonth()

                    locale: root.locale

                    onLocaleChanged: {
                        model = Array.from({
                            "length": 12
                        }, (x, i) => root.locale.monthName(i, Locale.LongFormat));
                    }
                    onActivated: {
                        calendarListView.updateCurrentIndex();
                    }
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            DayOfWeekRow {
                id: weekRow

                Layout.alignment: Qt.AlignHCenter
                implicitWidth: calendarListView.width

                locale: root.locale

                delegate: ScalableLabel {
                    required property string shortName

                    text: shortName
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            ListView {
                id: calendarListView

                function updateCurrentIndex() {
                    currentIndex = calendarModel.indexOf(yearSpinBox.value, monthCombo.month);
                }

                implicitHeight: contentItem.childrenRect.height
                Layout.alignment: Qt.AlignHCenter

                highlightMoveDuration: 0
                snapMode: ListView.SnapOneItem
                orientation: ListView.Horizontal
                clip: true

                reuseItems: true

                // highlightRangeMode: ListView.StrictlyEnforceRange
                model: CalendarModel {
                    id: calendarModel

                    from: new Date(1980, 0, 0)
                    to: new Date(new Date().getFullYear(), 11, 31) // NOTE: Current implementation doesn't handle range of months
                }

                delegate: CalendarDelegate {
                    onImplicitWidthChanged: {
                        ListView.view.implicitWidth = implicitWidth;
                    }
                }

                currentIndex: -1

                Component.onCompleted: {
                    updateCurrentIndex();
                }

                onCurrentIndexChanged: {
                    yearSpinBox.value = calendarModel.yearAt(currentIndex);
                    monthCombo.currentIndex = calendarModel.monthAt(currentIndex);
                }
            }

            Item {
                Layout.minimumHeight: 20
            }
        }

        Connections {
            target: root

            function onSelectedDateChanged() {
                datePopup.updateResetButton();
            }
        }
    }

    QtObject {
        id: internal

        property date selectedDate: new Date(NaN)
        property date prevSelectedDate: new Date(NaN)
    }

    component CalendarDelegate: MonthGrid {
        id: monthGrid

        required property var model

        locale: root.locale
        year: model.year
        month: model.month

        implicitWidth: contentItem.implicitWidth
        implicitHeight: contentItem.implicitHeight

        delegate: RoundButton {
            id: delegateToolButton

            required property var model
            required property int month
            required property int day
            required property int year
            required property date date

            flat: true

            padding: 0
            leftInset: 0
            rightInset: 0
            topInset: 2
            bottomInset: 2
            Material.roundedScale: Material.FullScale

            opacity: month === monthGrid.month ? 1 : 0.8
            enabled: month === monthGrid.month

            text: root.locale.toString(date, "d")
            checked: enabled && internal.selectedDate.getTime() === date.getTime()

            Material.theme: checked ? Material.Dark : root.Material.theme
            Material.accent: checked ? Material.foreground : root.Material.foreground
            Material.background: checked ? Material.primary : "transparent"

            onClicked: {
                if (checked) {
                    internal.selectedDate = new Date(NaN);
                } else {
                    internal.selectedDate = date;
                }
            }
        }
    }
}
