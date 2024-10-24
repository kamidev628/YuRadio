import QtQuick

Item {
    id: root

    property alias text: textLabel.text
    property alias font: textLabel.font
    property alias fontPointSize: textLabel.fontPointSize

    property alias wrapMode: textLabel.wrapMode
    property alias elide: textLabel.elide
    property alias lineHeight: textLabel.lineHeight
    property alias fontSizeMode: textLabel.fontSizeMode

    property int averageReadingSpeedCPM: 1000 // 200 wpm -> 1000 cpm

    property bool enableMarqueeEffect: true

    QtObject {
        id: internal

        property bool enableMarqueeEffect: textLabel.contentWidth <= root.width ? false : root.enableMarqueeEffect
    }

    clip: true

    implicitWidth: textLabel.implicitWidth
    implicitHeight: textLabel.implicitHeight

    onTextChanged: {
        if (slidingAnimation.running) {
            slidingAnimation.restart();
        }
    }

    ScalableLabel {
        id: textLabel

        width: parent.width
        height: parent.height

        SequentialAnimation {
            id: slidingAnimation

            running: root.visible && internal.enableMarqueeEffect
            loops: Animation.Infinite

            onRunningChanged: {
                textLabel.x = 0;
            }

            PauseAnimation {
                duration: 2000
            }

            NumberAnimation {
                target: textLabel
                property: "x"
                from: 0
                to: -textLabel.contentWidth
                duration: root.text.length / root.averageReadingSpeedCPM * 60 * 1000
            }
        }
    }

    ShaderEffectSource {
        id: shaderEffectSource

        visible: internal.enableMarqueeEffect
        sourceItem: textLabel

        x: textLabel.x + textLabel.contentWidth

        width: textLabel.contentWidth
        height: parent.height
        sourceRect: Qt.rect(0, 0, width, height)
    }
}
