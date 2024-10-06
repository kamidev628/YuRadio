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
    inputMethodHints: Qt.ImhDate
    editable: false

    popup: Dialog {
        id: datePopup

        width: Math.max(root.width, contentItem.implicitWidth)
        implicitHeight: contentItem.implicitHeight
        implicitWidth: contentItem.implicitWidth

        Material.roundedScale: Material.NotRounded
        standardButtons: Dialog.Ok | Dialog.Cancel | Dialog.Reset

        padding: 8

        rightMargin: 2
        leftMargin: 2
        bottomMargin: 2
        topMargin: 2

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
            root.displayText = root.selectedDate.toLocaleDateString(root.locale, Locale.ShortFormat);
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
                locale: root.locale

                delegate: ScalableLabel {
                    required property string shortName

                    text: shortName
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Layout.fillWidth: true
                Layout.preferredWidth: calendarListView.width
            }

            ListView {
                id: calendarListView

                function updateCurrentIndex() {
                    let index = calendarModel.indexOf(yearSpinBox.value, monthCombo.month);
                    setCurrentIndex(index);
                }

                function setCurrentIndex(index) {
                    positionViewAtIndex(index, ListView.SnapPosition);
                    currentIndex = index;
                }

                snapMode: ListView.SnapOneItem
                orientation: ListView.Horizontal
                clip: true

                // highlightRangeMode: ListView.StrictlyEnforceRange
                model: CalendarModel {
                    id: calendarModel

                    from: new Date(1980, 0, 0)
                    to: new Date(new Date().getFullYear(), 11, 31) // NOTE: Current implementation doesn't handle range of months
                }

                delegate: CalendarDelegate {
                    Component.onCompleted: {
                        ListView.view.implicitWidth = implicitWidth;
                        ListView.view.implicitHeight = implicitHeight;
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

        delegate: Rectangle {
            id: monthGridDelegate

            required property var model
            required property int month
            required property int day
            required property int year
            required property date date

            implicitWidth: delegateToolButton.implicitWidth
            implicitHeight: delegateToolButton.implicitHeight
            radius: height / 2
            color: delegateToolButton.checked ? Material.primary : "transparent"

            ToolButton {
                id: delegateToolButton

                flat: true

                anchors.fill: parent

                opacity: monthGridDelegate.month === monthGrid.month ? 1 : 0.8
                enabled: monthGridDelegate.month === monthGrid.month

                text: root.locale.toString(monthGridDelegate.date, "d")
                checked: enabled && internal.selectedDate.getTime() === monthGridDelegate.date.getTime()

                Material.theme: checked ? Material.Dark : root.Material.theme
                Material.accent: checked ? Material.foreground : root.Material.foreground

                onClicked: {
                    internal.selectedDate = monthGridDelegate.date;
                }
            }
        }
    }
}
