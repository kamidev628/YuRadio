pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

ScalableComboBox {
    id: root

    property list<string> stringModel
    property list<string> completionModel: stringModel.filter(x => x.toLowerCase().includes(input.text.toLowerCase())).sort((a, b) => {
        return ('' + a.attr).localeCompare(b.attr);
    })

    model: stringModel
    selectTextByMouse: true

    contentItem: FocusScope {
        implicitWidth: input.implicitWidth
        implicitHeight: input.implicitHeight

        TextField {
            id: input

            leftPadding: Material.textFieldHorizontalPadding
            topPadding: Material.textFieldVerticalPadding
            bottomPadding: Material.textFieldVerticalPadding

            background.opacity: 0

            anchors.fill: parent
            focus: true

            text: root.editable ? root.editText : root.displayText

            enabled: root.editable
            autoScroll: root.editable
            readOnly: root.down
            inputMethodHints: root.inputMethodHints
            validator: root.validator
            selectByMouse: root.selectTextByMouse

            color: root.enabled ? root.Material.foreground : root.Material.hintTextColor
            selectionColor: root.Material.accentColor
            selectedTextColor: root.Material.primaryHighlightedTextColor
            verticalAlignment: Text.AlignVCenter

            cursorDelegate: CursorDelegate {}

            onTextEdited: {
                root.editText = text;
                if (text.length === 0) {
                    Qt.callLater(() => listViewCompletion.currentIndex = -1);
                }
                completionPopup.open();
            }

            onAccepted: {
                let index = root.find(text);
                if (index === -1 && root.completionModel.length > 0 && text.length > 0) {
                    index = root.find(root.completionModel[listViewCompletion.currentIndex]);
                }
                if (root.currentIndex === index) {
                    root.editText = root.textAt(root.currentIndex);
                }
                root.currentIndex = index;
                completionPopup.close();
            }

            function tabPressed(event: var, increment: bool): void {
                if (completionPopup.opened && root.completionModel.length > 0) {
                    if (increment) {
                        listViewCompletion.incrementCurrentIndex();
                    } else {
                        listViewCompletion.decrementCurrentIndex();
                    }
                    event.accepted = true;
                } else {
                    event.accepted = false;
                }
            }

            Keys.onBacktabPressed: event => tabPressed(event, false)
            Keys.onTabPressed: event => tabPressed(event, true)
        }
    }

    Popup {
        id: completionPopup

        y: root.height
        width: root.width
        height: Math.min(contentItem.implicitHeight + verticalPadding * 2, root.Window.height - root.mapToGlobal(0, 0).y - bottomMargin - root.height)

        bottomMargin: 12
        leftMargin: 6
        rightMargin: 6

        modal: false

        contentItem: ListView {
            id: listViewCompletion

            clip: true
            reuseItems: true
            focus: true

            currentIndex: -1

            implicitHeight: contentHeight
            model: root.completionModel
            highlightMoveDuration: 50

            delegate: ItemDelegate {
                required property string modelData
                required property int index

                focus: true
                focusPolicy: Qt.TabFocus
                highlighted: listViewCompletion.currentIndex === index
                Material.foreground: listViewCompletion.currentIndex === index ? ListView.view.contentItem.Material.accent : ListView.view.contentItem.Material.foreground

                width: ListView.view.width
                text: modelData

                onClicked: {
                    root.currentIndex = root.find(text);
                    completionPopup.close();
                }
            }

            ScrollBar.vertical: ScrollBar {}
        }
    }

    Connections {
        target: root

        function onActiveFocusChanged() {
            if (!root.activeFocus) {
                completionPopup.close();
                listViewCompletion.currentIndex = -1;
                root.editText = root.textAt(root.currentIndex);
            }
        }
    }
}
