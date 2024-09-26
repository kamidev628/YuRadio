import QtQuick
import QtQml

import YuRadioContents

Item {
    id: root

    property Item target: parent

    property int fontPointSize: -1
    property int defaultPixelSize: -1

    Binding {
        target: root.target
        property: "font.pointSize"
        when: root.fontPointSize !== -1
        value: AppConfig.getScaledFont(root.fontPointSize)
    }

    Binding {
        target: root.target
        property: "font.pixelSize"
        when: root.fontPointSize === -1 && root.defaultPixelSize !== -1
        value: AppConfig.getScaledFont(root.defaultPixelSize)
    }

    Connections {
        target: root

        Component.onCompleted: {
            root.defaultPixelSize = root.target.font.pixelSize;
        }
    }
}
