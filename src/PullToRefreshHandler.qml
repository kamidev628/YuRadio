import QtQuick

Item {
    id: root
    anchors.fill: parent

    property Flickable target: parent as Flickable
    property int threshold: 100

    readonly property alias isPullDown: internal.isPullDown
    readonly property alias isPullUp: internal.isPullUp
    readonly property alias isPullingDown: internal.isPullingDown
    readonly property alias isPullingUp: internal.isPullingUp
    readonly property alias progress: internal.progress

    property alias refreshIndicator: refreshIndicatorLoader
    property int dragDirection: PullToRefreshHandler.TopToBottom

    signal pullDown
    signal pullUp
    signal pullDownRelease
    signal pullUpRelease

    property Component refreshIndicatorDelegate: PullToRefreshIndicator {}

    enum DragDirection {
        TopToBottom,
        BottomToTop
    }

    QtObject {
        id: internal
        property bool isPullDown: false
        property bool isPullUp: false
        property bool isPullingDown: false
        property bool isPullingUp: false
        property int threshold: root.threshold

        property real progress: {
            if (!root.enabled || !root.target || !threshold)
                return 0;
            return Math.min(Math.abs(root.target.verticalOvershoot) / threshold, 1.0);
        }
    }

    Connections {
        target: root.target
        enabled: root.enabled

        function onVerticalOvershootChanged() {
            console.log("verticalOvershoot", root.target.verticalOvershoot);
            console.log("dragging", root.target.dragging);
            if (!root.target.verticalOvershoot) {
                internal.isPullingDown = false;
                internal.isPullingUp = false;
                if (internal.isPullDown) {
                    internal.isPullDown = false;
                    root.pullDownRelease();
                }
                if (internal.isPullUp) {
                    internal.isPullUp = false;
                    root.pullUpRelease();
                }
            }
            if (root.target.verticalOvershoot < 0 && root.target.dragging) {
                internal.isPullingDown = true;
                if (-root.target.verticalOvershoot > internal.threshold) {
                    internal.isPullDown = true;
                    root.pullDown();
                }
            } else if (root.target.verticalOvershoot > 0 && root.target.dragging) {
                internal.isPullingUp = true;
                if (root.target.verticalOvershoot > internal.threshold) {
                    internal.isPullUp = true;
                    root.pullUp();
                }
            }
        }
    }

    Loader {
        id: refreshIndicatorLoader

        property real dragProgress: internal.progress
        property int threshold: internal.threshold
        property PullToRefreshHandler handler: root as PullToRefreshHandler

        active: root.enabled && internal.progress > 0
        sourceComponent: root.refreshIndicatorDelegate
    }
}
