import QtQuick
import QtQuick.Controls.Material

ScalableButton {
    id: root

    property string link

    Material.theme: Material.Light
    Material.background: Material.color(Material.Grey, Material.Shade200)

    icon.source: "images/itunes-logo.svg"
    icon.color: "transparent"

    onClicked: {
        Qt.openUrlExternally(root.link);
    }
}
