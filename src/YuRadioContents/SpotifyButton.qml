import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Button {
    id: root

    property string link

    Material.foreground: Material.color(Material.Grey, Material.Shade200)
    Material.background: Material.color(Material.Grey, Material.Shade900)

    icon.source: "images/spotify-logo.svg"
    icon.color: "transparent"

    onClicked: {
        Qt.openUrlExternally(root.link);
    }
}
