pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

ScalableComboBox {
    id: root

    property string headerText: "SELECT ALL"

    onAccepted: {
        if (find(editText) === -1) {
            editText = textAt(0);
        }
    }

    Binding {
        target: root.popup.contentItem
        property: "header"
        value: Component {
            ItemDelegate {
                text: root.headerText
                width: ListView.view.width
                onClicked: {
                    root.currentIndex = -1;
                    root.popup.close();
                }
            }
        }
    }
}
