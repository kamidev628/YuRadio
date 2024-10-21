import QtQml
import QtCore
import QtQuick.Controls

ApplicationWindow {
    id: root

    property int bottomMargin: 0

    Settings {
        property alias windowX: root.x
        property alias windowY: root.y
        property alias windowWidth: root.width
        property alias windowHeight: root.height
        property alias windowVisibility: root.visibility
    }
}
