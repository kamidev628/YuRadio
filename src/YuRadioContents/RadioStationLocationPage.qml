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

    MapView {
        id: mapView
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
        Component.onCompleted: {
            map.addMapItem(marker);
        }

        map.plugin: mapPlugin
        map.activeMapType: map.supportedMapTypes[map.supportedMapTypes.length - 1]
        map.center: QtPositioning.coordinate(root.stationLatitude, root.stationLongitude)
        map.zoomLevel: 14
        Shortcut {
            enabled: mapView.map.zoomLevel < mapView.map.maximumZoomLevel
            sequence: StandardKey.ZoomIn
            onActivated: mapView.map.zoomLevel = Math.round(mapView.map.zoomLevel + 1)
        }
        Shortcut {
            enabled: mapView.map.zoomLevel > mapView.map.minimumZoomLevel
            sequence: StandardKey.ZoomOut
            onActivated: mapView.map.zoomLevel = Math.round(mapView.map.zoomLevel - 1)
        }
    }
}
