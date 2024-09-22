import QtQuick

import YuRadioContents

Rectangle {
    width: GridView.view.currentItem?.width ?? 0
    height: GridView.view.currentItem?.height ?? 0
    y: GridView.view.currentItem?.y ?? 0
    x: GridView.view.currentItem?.x ?? 0

    color: "lightsteelblue"
    opacity: 0.6

    Behavior on x {
        enabled: AppSettings.enableSelectionAnimation
        SpringAnimation {
            id: xAnim

            spring: 4
            damping: 0.5
            duration: 80
        }
    }
    Behavior on y {
        enabled: AppSettings.enableSelectionAnimation
        SpringAnimation {
            id: yAnim

            spring: 4
            damping: 0.5
        }
    }
}
