import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

Button {
    id: root

    property color buttonColor: Material.primary

    padding: 0

    Material.foreground: checked ? Material.color(Material.Grey, Material.Shade500) : buttonColor
    Material.accent: Material.color(Material.Grey, Material.Shade100)

    checkable: true

    background: Rectangle {
        anchors.fill: parent

        radius: height / 2
        color: root.checked ? root.buttonColor : (AppConfig.isDarkTheme ? root.buttonColor.lighter(0.3) : "transparent")
        border.width: 1
        border.color: root.buttonColor

        Ripple {
            clipRadius: parent.radius
            clip: true

            width: parent.width
            height: parent.height
            pressed: root.pressed
            anchor: root

            active: root.down || root.visualFocus || root.hovered
            color: root.flat && root.highlighted ?  root.Material.highlightedRippleColor : root.Material.rippleColor
        }
    }
}
