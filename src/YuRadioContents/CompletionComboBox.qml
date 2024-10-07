pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

ScalableComboBox {
    id: root

    property list<string> stringModel
    property list<string> completionModel: stringModel.filter(x => x.toLowerCase().includes(input.text)).sort((a, b) => {
        return ('' + a.attr).localeCompare(b.attr);
    })

    property string textBeforeCompletion

    model: stringModel
    displayText: textBeforeCompletion
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
                completionPopup.open();
            }
            onAccepted: {
                let index = root.find(text);
                if (index === -1 && root.completionModel.length > 0 && text.length > 0) {
                    index = root.find(root.completionModel[0]);
                }
                root.currentIndex = index;
            }
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

            implicitHeight: contentHeight
            model: root.completionModel

            delegate: ItemDelegate {
                required property string modelData
                required property int index

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
        target: input
    }

    Connections {
        target: root

        function onActiveFocusChanged() {
            if (!root.activeFocus) {
                completionPopup.close();
            }
        }
    }
}
