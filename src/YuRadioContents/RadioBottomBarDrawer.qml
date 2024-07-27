import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material
import Qt.labs.animation

Item {
    id: root

    default property alias data: contentItem.data
    property alias dragHandler: dragHandler

    required property real minimumHeight
    required property real maximumHeight

    property real progress: (root.height - root.minimumHeight) / (root.maximumHeight - root.minimumHeight)

    property Component background: Rectangle {}

    height: minimumHeight

    function open() {
        openCloseAnimation.to = maximumHeight;
        openCloseAnimation.start();
    }

    function close() {
        openCloseAnimation.to = minimumHeight;
        openCloseAnimation.start();
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

    BoundaryRule on height {
        id: heightBoundaryRule
        maximum: root.maximumHeight
        minimum: root.minimumHeight

        minimumOvershoot: 5
        maximumOvershoot: 5
    }

    NumberAnimation on height {
        id: openCloseAnimation
        duration: 200
        onFinished: {
            if (root.height >= root.maximumHeight) {
                root.height = Qt.binding(() => root.maximumHeight);
            } else if (root.height <= root.minimumHeight) {
                root.height = Qt.binding(() => root.minimumHeight);
            }
        }
    }

    TapHandler {
        onTapped: {
            root.open();
        }
    }

    DragHandler {
        id: dragHandler
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
            if (centroid.velocity.y > 1000) {
                root.close();
            } else if (centroid.velocity.y < -1000) {
                root.open();
            }
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

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 5

            Layout.preferredHeight: 4
            Layout.preferredWidth: parent.width / 10
            radius: height / 2

            color: Material.color(Material.Grey, Material.Shade800)
            opacity: 0.7
        }

        Item {
            id: contentItem
            focus: true

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
