pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

/* NOTE: Currently I can't qualify access due to cyclic dependency */
Pane {
    id: root

    property bool fullyRefreshed: false

    signal refreshed

    width: 32
    height: 32
    x: (handler.width - width) / 2
    y: handler.maximumProgress * (handler.maximumThreshold + height) - height

    padding: 0
    Material.elevation: 4
    background: Rectangle {
        color: Material.background
        radius: width / 2

        layer.enabled: root.enabled && root.Material.elevation > 0
        layer.effect: ElevationEffect {
            elevation: root.Material.elevation
        }
    }

    onFullyRefreshedChanged: {
        if (fullyRefreshed) {
            root.state = "";
            root.refreshed();
        }
    }

    states: [
        State {
            name: "refreshed"
            extend: "release"

            when: handler.isPulling && !handler.refreshCondition

            PropertyChanges {
                root.opacity: 0
                root.scale: 0
            }
        },
        State {
            name: "release"
            when: handler.isPulling

            PropertyChanges {
                root.y: minimumThreshold
                progressIndicatorPathAnimationSweep.running: true
                progressIndicatorPathAnimation.running: true
                progressIndicatorPathArc.sweepAngle: {
                    progressIndicatorPathArc.sweepAngle = progressIndicatorPathArc.sweepAngle;
                }
                progressIndicatorPathArc.startAngle: {
                    progressIndicatorPathArc.startAngle = progressIndicatorPathArc.startAngle;
                }
            }
        },
        State {
            name: "updateFullyRefreshed"
            PropertyChanges {
                root.fullyRefreshed: !handler.target.verticalOvershoot
            }
        }
    ]

    transitions: [
        Transition {
            to: "release"

            PropertyAnimation {
                target: root
                properties: "y"
                duration: 100
            }
        },
        Transition {
            id: refreshedTransition
            to: "refreshed"

            SequentialAnimation {
                PropertyAnimation {
                    target: root
                    properties: "opacity,scale"
                    duration: 200
                }
                PropertyAction {
                    target: root
                    property: "state"
                    value: "updateFullyRefreshed"
                }
            }
        }
    ]

    Shape {
        id: progressIndicator

        anchors.fill: parent

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            id: progressIndicatorPath

            strokeWidth: 3
            strokeColor: root.Material.accent
            fillColor: "transparent"

            PathAngleArc {
                id: progressIndicatorPathArc

                centerX: progressIndicator.width / 2
                centerY: progressIndicator.height / 2
                radiusX: progressIndicator.width / 2 - 5
                radiusY: progressIndicator.height / 2 - 5
                startAngle: -90 + (360 * handler.maximumProgress / 2)
                sweepAngle: 290 * handler.minimumProgress

                NumberAnimation on startAngle {
                    id: progressIndicatorPathAnimation

                    from: progressIndicatorPathArc.startAngle
                    to: from + 360
                    duration: 800

                    running: false
                    loops: Animation.Infinite
                }

                property SequentialAnimation anim: SequentialAnimation {
                    id: progressIndicatorPathAnimationSweep

                    property int sweepDuration: (progressIndicatorPathAnimation.duration * 5 / 2 - pauseAnimation.duration) / 2

                    NumberAnimation {
                        target: progressIndicatorPathArc
                        property: "sweepAngle"
                        from: 290
                        to: 10
                        duration: progressIndicatorPathAnimationSweep.sweepDuration
                    }
                    PauseAnimation {
                        id: pauseAnimation
                        duration: 10
                    }
                    NumberAnimation {
                        target: progressIndicatorPathArc
                        property: "sweepAngle"
                        from: 10
                        to: 290
                        duration: progressIndicatorPathAnimationSweep.sweepDuration
                    }

                    running: false
                    loops: Animation.Infinite
                }
            }
        }
    }
}
