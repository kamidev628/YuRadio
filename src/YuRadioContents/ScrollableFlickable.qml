import QtQuick
import QtQuick.Controls

import YuRadioContents

/* NOTE: Use this when multiple scrollviews are stacked */
Flickable {
    id: root

    interactive: AppConfig.isMobile

    MouseArea {
        enabled: !root.interactive
        anchors.fill: parent
        preventStealing: true

        onWheel: event => {
            if (event.angleDelta.y > 0) {
                if (root.atYBeginning) {
                    event.accepted = false;
                } else {
                    scrollBar.decrease();
                }
            } else {
                if (root.atYEnd) {
                    event.accepted = false;
                } else {
                    scrollBar.increase();
                }
            }
        }
    }

    ScrollBar.vertical: ScrollBar {
        id: scrollBar
        visible: false
    }
}
