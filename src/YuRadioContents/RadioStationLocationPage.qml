import QtQuick

import QtLocation
import QtPositioning

import YuRadioContents

Item {
    id: root

    required property real stationLatitude
    required property real stationLongitude

    Plugin {
        id: mapPlugin

        name: "osm"
        locales: [AppSettings.locale]

        PluginParameter {
            name: "osm.mapping.custom.host"
            value: "https://tile.openstreetmap.org/"
        }
    }

    Map {
        id: map

        property geoCoordinate startCentroid

        anchors.fill: parent

        plugin: mapPlugin
        activeMapType: supportedMapTypes[supportedMapTypes.length - 1]
        center: QtPositioning.coordinate(root.stationLatitude, root.stationLongitude)
        zoomLevel: 14

        MapQuickItem {
            id: marker

            coordinate: QtPositioning.coordinate(root.stationLatitude, root.stationLongitude)
            anchorPoint.x: image.width / 2
            anchorPoint.y: image.height

            sourceItem: Image {
                id: image
                source: "images/location.svg"
                sourceSize: Qt.size(32, 32)
            }
        }

        Timer {
            id: dragDelayTimer
            interval: 100
        }

        PinchHandler {
            id: pinchHandler

            target: null

            onActiveChanged: if (active) {
                map.startCentroid = map.toCoordinate(centroid.position, false);
            } else {
                dragDelayTimer.start();
            }
            onScaleChanged: delta => {
                map.zoomLevel += Math.log2(delta);
                map.alignCoordinateToPoint(map.startCentroid, centroid.position);
            }
            onRotationChanged: delta => {
                map.bearing -= delta;
                map.alignCoordinateToPoint(map.startCentroid, centroid.position);
            }
            grabPermissions: PointerHandler.TakeOverForbidden
        }

        WheelHandler {
            id: wheelHandler

            onWheel: event => {
                const location = map.toCoordinate(point.position);
                map.zoomLevel += Math.cbrt(event.angleDelta.y) / 30;
                map.alignCoordinateToPoint(location, point.position);
            }
            rotationScale: 1 / 120
        }

        DragHandler {
            id: dragHandler

            target: null

            onActiveChanged: if (active) {
                map.startCentroid = map.toCoordinate(centroid.position, false);
            }

            onTranslationChanged: delta => {
                map.alignCoordinateToPoint(map.startCentroid, centroid.position);
            }
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
