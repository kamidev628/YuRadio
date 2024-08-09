import QtQuick

Rectangle {
    width: GridView.view.currentItem?.width ?? 0
    height: GridView.view.currentItem?.height ?? 0
    y: GridView.view.currentItem?.y ?? 0
    x: GridView.view.currentItem?.x ?? 0

    color: "lightsteelblue"
    opacity: 0.6

    Behavior on x {
        SpringAnimation {
            id: xAnim
            spring: 4
            damping: 0.5
            duration: 100
        }
    }
    Behavior on y {
        SequentialAnimation {
            PauseAnimation {
                duration: xAnim.running ? xAnim.duration + 200 : 0
            }
            SpringAnimation {
                id: yAnim
                spring: 4
                damping: 0.5
            }
        }
    }
}
