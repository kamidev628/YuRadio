import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Label {
    id: homePage

    property string linkText
    property string link

    text: link ? `<a href="${link}"><font color="${Material.color(Material.Blue)}">${linkText}</font></a>` : ''
    textFormat: Text.RichText
    onLinkActivated: link => Qt.openUrlExternally(link)

    font.pointSize: 14

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
    }
}
