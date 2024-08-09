pragma ComponentBehavior: Bound

import QtQuick

GridView {
    id: root

    required property real minimumItemWidth
    property int numItemsInRow: root.width / internal.itemWidth

    QtObject {
        id: internal

        property real itemWidth: Math.min(root.width, root.minimumItemWidth)
        property real totalItemsWidth: root.numItemsInRow * itemWidth
        property real remaindedWidth: root.width - totalItemsWidth
        property real evenlyDistributedWidth: Math.max(remaindedWidth / root.numItemsInRow, 0)
    }

    cellWidth: internal.itemWidth + internal.evenlyDistributedWidth
}
