import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material
import Qt.labs.animation

import YuRadioContents

Item {
    id: root

    default property alias data: contentItem.data

    required property real minimumHeight
    required property real maximumHeight
    property bool interactive: true

    property real progress: (root.height - root.minimumHeight) / (root.maximumHeight - root.minimumHeight)

    property Component background: Rectangle {}

    function open(): void {
        if (root.height != maximumHeight) {
            openCloseAnimation.to = maximumHeight;
            openCloseAnimation.start();
        }
    }

    function close(): void {
        if (root.height != minimumHeight) {
            openCloseAnimation.to = minimumHeight;
            openCloseAnimation.start();
        }
    }

    function returnToClosestBoundary(): void {
        if (root.progress < 0.5) {
            root.close();
        } else {
            root.open();
        }
    }

    function _restoreHeightBinding(): void {
        if (root.height >= root.maximumHeight) {
            root.height = Qt.binding(() => root.maximumHeight);
        } else {
            root.height = Qt.binding(() => root.minimumHeight);
        }
    }

    height: minimumHeight

    BoundaryRule on height {
        id: heightBoundaryRule

        maximum: root.maximumHeight
        minimum: root.minimumHeight

        minimumOvershoot: 5
        maximumOvershoot: 5

        onReturnedToBounds: root._restoreHeightBinding()
    }

    NumberAnimation on height {
        id: openCloseAnimation

        property real baseDuration: 200

        duration: baseDuration
        onFinished: root._restoreHeightBinding()
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

        onActiveChanged: {
            if (active) {
                openCloseAnimation.stop();
                return;
            }
            if (heightBoundaryRule.returnToBounds()) {
                return;
            }

            /* Calculate animation duration based on current velocity */
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

            color: Material.color(Material.Grey, AppConfig.isDarkTheme ? Material.Shade500 : Material.Shade800)
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
