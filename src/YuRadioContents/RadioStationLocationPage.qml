import QtQuick
import QtQuick.Controls
import QtLocation
import QtPositioning

Item {
    id: root

    required property real stationLatitude
    required property real stationLongitude

    property bool displayBackButton: true

    Plugin {
        id: mapPlugin
        name: "osm"
        locales: AppSettings.locale
        PluginParameter {
            name: "osm.mapping.custom.host"
            value: "https://tile.openstreetmap.org/"
        }
    }

    Map {
        id: map
        anchors.fill: parent

        MapQuickItem {
            id: marker
            anchorPoint.x: image.width / 2
            anchorPoint.y: image.height
            coordinate: QtPositioning.coordinate(root.stationLatitude, root.stationLongitude)
            sourceItem: Image {
                id: image
                source: "images/location.svg"
                sourceSize: Qt.size(32, 32)
            }
        }

        plugin: mapPlugin
        activeMapType: supportedMapTypes[supportedMapTypes.length - 1]
        center: QtPositioning.coordinate(root.stationLatitude, root.stationLongitude)
        zoomLevel: 14

        property geoCoordinate startCentroid
        PinchHandler {
            id: pinchHandler
            target: null
            onActiveChanged: if (active) {
                map.startCentroid = map.toCoordinate(pinchHandler.centroid.position, false);
            }
            onScaleChanged: delta => {
                map.zoomLevel += Math.log2(delta);
                map.alignCoordinateToPoint(map.startCentroid, pinchHandler.centroid.position);
            }
            onRotationChanged: delta => {
                map.bearing -= delta;
                map.alignCoordinateToPoint(map.startCentroid, pinchHandler.centroid.position);
            }
            grabPermissions: PointerHandler.TakeOverForbidden
        }
        WheelHandler {
            id: wheelHandler
            // workaround for QTBUG-87646 / QTBUG-112394 / QTBUG-112432:
            // Magic Mouse pretends to be a trackpad but doesn't work with PinchHandler
            // and we don't yet distinguish mice and trackpads on Wayland either
            acceptedDevices: Qt.platform.pluginName === "cocoa" || Qt.platform.pluginName === "wayland" ? PointerDevice.Mouse | PointerDevice.TouchPad : PointerDevice.Mouse
            rotationScale: 1 / 120
            property: "zoomLevel"
        }
        DragHandler {
            id: dragHandler
            target: null
            onTranslationChanged: delta => map.pan(-delta.x, -delta.y)
        }
        Shortcut {
            enabled: map.zoomLevel < map.maximumZoomLevel
            sequence: StandardKey.ZoomIn
            onActivated: map.zoomLevel = Math.round(map.zoomLevel + 1)
        }
        Shortcut {
            enabled: map.zoomLevel > map.minimumZoomLevel
            sequence: StandardKey.ZoomOut
            onActivated: map.zoomLevel = Math.round(map.zoomLevel - 1)
        }
    }
}
