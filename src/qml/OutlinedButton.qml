import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Button {
    id: root

    padding: 0

    property color buttonColor: Material.primary

    Material.foreground: checked ? Material.color(Material.Grey, Material.Shade500) : buttonColor
    Material.accent: Material.color(Material.Grey, Material.Shade100)

    checkable: true

    background: Rectangle {
        anchors.fill: parent

        radius: height / 2
        color: root.checked ? root.buttonColor : (AppSettings.isDarkTheme ? root.buttonColor.lighter(0.3) : "transparent")
        border.width: 1
        border.color: root.buttonColor
    }
}
