import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material
import Qt.labs.animation

Item {
    id: root

    default property alias data: contentItem.data

    required property real minimumHeight
    required property real maximumHeight
    property bool interactive: true

    property real progress: (root.height - root.minimumHeight) / (root.maximumHeight - root.minimumHeight)

    property Component background: Rectangle {}

    function open() {
        if (root.height != maximumHeight) {
            openCloseAnimation.to = maximumHeight;
            openCloseAnimation.start();
        }
    }

    function close() {
        if (root.height != minimumHeight) {
            openCloseAnimation.to = minimumHeight;
            openCloseAnimation.start();
        }
    }

    function returnToClosestBoundary() {
        let velocityScale = (root.height - root.minimumHeight) / (root.maximumHeight - root.minimumHeight);
        /* TODO: Adjust duration of the animation based on velocity */
        if (root.height - root.minimumHeight < root.maximumHeight - root.height) {
            root.close();
        } else {
            root.open();
        }
    }

    height: minimumHeight

    BoundaryRule on height {
        id: heightBoundaryRule

        maximum: root.maximumHeight
        minimum: root.minimumHeight

        minimumOvershoot: 5
        maximumOvershoot: 5
    }

    NumberAnimation on height {
        id: openCloseAnimation

        property real baseDuration: 200

        duration: baseDuration
        onFinished: {
            if (root.height == root.maximumHeight) {
                root.height = Qt.binding(() => root.maximumHeight);
            } else if (root.height == root.minimumHeight) {
                root.height = Qt.binding(() => root.minimumHeight);
            }
        }
    }

    TapHandler {
        enabled: root.interactive
        onTapped: {
            root.open();
        }
    }

    DragHandler {
        id: dragHandler

        enabled: root.interactive
        target: root

        dragThreshold: 50

        yAxis.onActiveValueChanged: delta => {
            if (delta && Utils.sameSign(heightBoundaryRule.currentOvershoot, delta))
                root.height -= delta;
        }

        onActiveChanged: if (!active) {
            if (heightBoundaryRule.returnToBounds()) {
                return;
            }
            const threshold = 1000;
            const maxVelocity = 4000;
            const clampedVelocity = Utils.clamp(Math.abs(centroid.velocity.y), threshold, maxVelocity);
            const velocityProgress = (clampedVelocity - threshold) / (maxVelocity - threshold);
            const duration = openCloseAnimation.baseDuration * Math.exp(-3 / 2 * velocityProgress);
            openCloseAnimation.duration = duration;
            if (centroid.velocity.y > threshold) {
                root.close();
            } else if (centroid.velocity.y < -threshold) {
                root.open();
            }
            openCloseAnimation.duration = openCloseAnimation.baseDuration;
            root.returnToClosestBoundary();
        }
    }

    Loader {
        anchors.fill: parent

        sourceComponent: root.background
    }

    ColumnLayout {
        anchors.fill: parent

        Rectangle {
            id: bottomBarHandle

            Layout.preferredHeight: 4
            Layout.preferredWidth: Math.min(parent.width / 10, 100)
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 5

            radius: height / 2

            color: Material.color(Material.Grey, Material.Shade800)
            opacity: 0.7
        }

        Item {
            id: contentItem

            Layout.fillWidth: true
            Layout.fillHeight: true

            focus: true
        }
    }
}
