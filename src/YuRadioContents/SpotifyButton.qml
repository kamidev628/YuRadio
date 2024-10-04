import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

ScalableButton {
    id: root

    property string link

    Material.theme: Material.Dark
    Material.foreground: Material.color(Material.Grey, Material.Shade200)
    Material.background: Material.color(Material.Grey, Material.Shade900)

    icon.source: "images/spotify-logo.svg"
    icon.color: "transparent"

    onClicked: {
        Qt.openUrlExternally(root.link);
    }
}
