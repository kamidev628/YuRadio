pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

Pane {
    id: root

    width: 32
    height: 32

    x: (handler.width - width) / 2
    y: maximumProgress * (maximumThreshold + height) - height

    property bool fullyRefreshed: false
    onFullyRefreshedChanged: {
        root.state = "";
    }

    states: [
        State {
            name: "refreshed"
            extend: "release"

            when: isPulling && !refreshCondition

            PropertyChanges {
                root.opacity: 0
                root.scale: 0
            }
        },
        State {
            name: "release"
            when: isPulling

            PropertyChanges {
                canvas.minimumProgressAngle: 0
                root.y: minimumThreshold
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
                ScriptAction {
                    script: {
                        root.fullyRefreshed = Qt.binding(() => {
                            return !handler.target.verticalOvershoot;
                        });
                    }
                }
            }
        }
    ]

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

    Canvas {
        id: canvas
        anchors.fill: parent

        property real minimumProgressAngle: minimumProgress
        property real maximumProgressAngle: maximumProgress

        NumberAnimation on minimumProgressAngle {
            running: refreshCondition && isPulling
            loops: Animation.Infinite

            duration: 500

            from: 0
            to: 1
        }

        onMinimumProgressAngleChanged: {
            canvas.requestPaint();
        }

        onMaximumProgressAngleChanged: {
            canvas.requestPaint();
        }

        onPaint: {
            let ctx = getContext("2d");
            ctx.reset();
            let x = width / 2;
            let y = height / 2;
            let radius = width / 2 - 5;
            let startAngle = -Math.PI / 2; // top of circle
            let endAngle = startAngle + 2 * Math.PI - Math.PI / 3; // left-top side of circle

            let progressAngle;
            let shift;
            if (!isPulling) {
                progressAngle = startAngle + (endAngle - startAngle) * minimumProgressAngle;
                shift = Math.PI * maximumProgressAngle;
            } else {
                progressAngle = endAngle;
                shift = 2 * Math.PI * minimumProgressAngle;
            }
            ctx.lineWidth = 3;
            ctx.strokeStyle = Material.accent;
            ctx.beginPath();
            ctx.arc(x, y, radius, startAngle + shift, progressAngle + shift);
            ctx.stroke();
        }
    }
}
