import QtQuick

Rectangle {
    width: ListView.view.currentItem?.width ?? 0
    height: ListView.view.currentItem?.height ?? 0
    y: ListView.view.currentItem?.y ?? 0

    color: "lightsteelblue"
    opacity: 0.6
    Behavior on y {
        SpringAnimation {
            spring: 4
            damping: 0.5
        }
    }
}
