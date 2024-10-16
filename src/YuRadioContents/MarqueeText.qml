import QtQuick

Item {
    id: root

    property alias text: textLabel.text
    property alias font: textLabel.font
    property alias fontPointSize: textLabel.fontPointSize

    property int wrapMode: textLabel.wrapMode
    property int elide: textLabel.elide

    property int averageReadingSpeedCPM: 1000 // 200 wpm -> 1000 cpm

    property bool enableMarqueeEffect: true

    clip: true

    implicitWidth: textLabel.implicitWidth
    implicitHeight: textLabel.implicitHeight

    onTextChanged: {
        if (slidingAnimation.running) {
            slidingAnimation.restart();
        }
    }

    states: [
        State {
            when: textLabel.contentWidth <= root.width || !root.enableMarqueeEffect

            PropertyChanges {
                slidingAnimation.running: false
                shaderEffectSource.visible: false
                textLabel.x: 0
            }
        },
        State {
            when: true

            PropertyChanges {
                textLabel.x: 0
            }
        }
    ]

    ScalableLabel {
        id: textLabel

        width: parent.width
        height: parent.height

        elide: root.enableMarqueeEffect ? Text.ElideNone : root.elide
        wrapMode: root.enableMarqueeEffect ? Text.NoWrap : root.wrapMode

        SequentialAnimation {
            id: slidingAnimation

            running: root.visible
            loops: Animation.Infinite

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

        sourceItem: textLabel
        visible: true

        x: textLabel.x + textLabel.contentWidth

        width: textLabel.contentWidth
        height: parent.height
        sourceRect: Qt.rect(0, 0, width, height)
    }
}
