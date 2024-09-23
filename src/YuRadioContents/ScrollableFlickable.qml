import QtQuick
import QtQuick.Controls

import YuRadioContents

/* NOTE: Use this when multiple scrollviews are stacked */
Flickable {
    id: root

    WheelHandler {
        blocking: false
        acceptedDevices: PointerDevice.Mouse
        enabled: root.interactive
        onWheel: event => {
            if (event.angleDelta.y > 0) {
                if (root.atYBeginning) {
                    root.interactive = false;
                }
            } else {
                if (root.atYEnd) {
                    root.interactive = false;
                }
            }
            event.accepted = false;
            Qt.callLater(() => root.interactive = true);
        }
    }

    ScrollBar.vertical: ScrollBar {
        id: scrollBar
        visible: false
    }
}
