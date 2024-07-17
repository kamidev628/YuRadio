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
    y: dragProgress * (threshold + height) - height

    padding: 0

    onYChanged: {
        canvas.requestPaint();
    }

    transform: Rotation {
        origin.x: root.width / 2
        origin.y: root.height / 2
        angle: dragProgress * 180
    }

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

        onPaint: {
            let ctx = getContext("2d");
            ctx.reset();
            let x = width / 2;
            let y = height / 2;
            let radius = width / 2 - 5;
            let startAngle = -Math.PI / 2; // top of circle
            let endAngle = startAngle + 2 * Math.PI - Math.PI / 3; // left-top side of circle
            let progressAngle = startAngle + (endAngle - startAngle) * dragProgress;
            ctx.lineWidth = 3;
            ctx.strokeStyle = Material.accent;
            ctx.beginPath();
            ctx.arc(x, y, radius, startAngle, progressAngle);
            ctx.stroke();
        }
    }
}
