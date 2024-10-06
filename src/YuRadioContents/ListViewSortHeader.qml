pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

import YuRadioContents

FocusScope {
    id: root

    required property ListModel model

    property int selectedIndex: 0
    property bool descending: true

    implicitHeight: columnLayout.implicitHeight
    implicitWidth: columnLayout.implicitWidth
    z: 3 // Delegates will have z = 2

    Rectangle {
        anchors.fill: parent

        color: root.Material.background
    }

    ColumnLayout {
        id: columnLayout

        anchors.fill: parent

        RowLayout {
            id: rowLayout

            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
                Layout.horizontalStretchFactor: 1
            }

            IconButton {
                id: orderByButton

                Layout.preferredWidth: Layout.preferredHeight + 8
                Layout.preferredHeight: listView.implicitHeight

                transform: Scale {
                    id: orderByButtonScale

                    yScale: root.descending ? 1 : -1
                    origin.x: orderByButton.width / 2
                    origin.y: orderByButton.height / 2
                }

                text: root.descending ? qsTr("Sort in ascending order") : qsTr("Sort in descending order")
                icon.source: 'images/sort.svg'
                icon.width: height
                icon.height: height

                icon.color: Material.primary

                onClicked: {
                    root.descending = !root.descending;
                }
            }

            ListView {
                id: listView

                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.maximumWidth: contentWidth
                Layout.horizontalStretchFactor: Utils.maxInteger

                implicitHeight: contentItem.childrenRect.height

                orientation: Qt.Horizontal
                spacing: 2

                clip: true
                focus: true

                model: root.model

                delegate: OutlinedButton {
                    required property int index
                    required property string name

                    topInset: 5
                    bottomInset: 5

                    topPadding: 15
                    bottomPadding: 15
                    leftPadding: 14
                    rightPadding: 14

                    focusPolicy: Qt.StrongFocus
                    focus: true

                    checked: index === root.selectedIndex
                    Accessible.name: qsTr("Sort by %1").arg(text)

                    text: name

                    onClicked: {
                        root.selectedIndex = index;
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.horizontalStretchFactor: 1
            }
        }
    }
}
