import QtQuick

Item {
    id: root

    property Flickable target: parent as Flickable
    property int minimumThreshold: 80
    property int maximumThreshold: 140
    property bool refreshCondition: false

    readonly property bool isPulling: isPullingDown || isPullingUp
    readonly property bool isProcessing: isPulling || target?.verticalOvershoot

    readonly property alias isPullDown: internal.isPullDown
    readonly property alias isPullUp: internal.isPullUp
    readonly property alias isPullingDown: internal.isPullingDown
    readonly property alias isPullingUp: internal.isPullingUp
    readonly property alias minimumProgress: internal.minimumProgress
    readonly property alias maximumProgress: internal.maximumProgress

    property alias refreshIndicator: refreshIndicatorLoader
    property Component refreshIndicatorDelegate: PullToRefreshIndicator {}

    signal pullDown
    signal pullUp
    signal pullDownRelease
    signal pullUpRelease

    signal refreshed

    anchors.fill: parent

    Loader {
        id: refreshIndicatorLoader

        property alias handler: root

        Connections {
            target: refreshIndicatorLoader.item

            function onRefreshed() {
                internal.isPullingDown = false;
                internal.isPullingUp = false;
                root.refreshed();
            }
        }

        active: root.enabled && root.isProcessing
        sourceComponent: root.refreshIndicatorDelegate
    }

    Connections {
        target: root.target
        enabled: root.enabled && !root.isPulling

        function onDraggingChanged() {
            if (!root.target.dragging) {
                if (internal.isPullDown) {
                    internal.isPullingDown = true;
                    internal.isPullDown = false;
                    root.pullDownRelease();
                }
                if (internal.isPullUp) {
                    internal.isPullingUp = true;
                    internal.isPullUp = false;
                    root.pullUpRelease();
                }
            }
        }

        function onVerticalOvershootChanged() {
            if (root.target.verticalOvershoot < 0) {
                if (-root.target.verticalOvershoot > root.minimumThreshold) {
                    internal.isPullDown = true;
                    root.pullDown();
                } else {
                    internal.isPullDown = false;
                }
            } else if (root.target.verticalOvershoot > 0) {
                if (root.target.verticalOvershoot > root.minimumThreshold) {
                    internal.isPullUp = true;
                    root.pullUp();
                } else {
                    internal.isPullUp = false;
                }
            }
        }
    }

    QtObject {
        id: internal

        property bool isPullDown: false
        property bool isPullUp: false
        property bool isPullingDown: false
        property bool isPullingUp: false

        property real minimumProgress: {
            if (!root.enabled || !root.target || !root.minimumThreshold)
                return 0;
            return Math.min(Math.abs(root.target.verticalOvershoot) / root.minimumThreshold, 1.0);
        }
        property real maximumProgress: {
            if (!root.enabled || !root.target || !root.maximumThreshold)
                return 0;
            return Math.min(Math.abs(root.target.verticalOvershoot) / root.maximumThreshold, 1.0);
        }
    }
}
