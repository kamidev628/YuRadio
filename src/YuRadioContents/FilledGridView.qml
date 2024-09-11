pragma ComponentBehavior: Bound

import QtQuick

GridView {
    id: root

    required property real minimumItemWidth
    property int numItemsInRow: Math.min(count, root.width / internal.itemWidth)

    cellWidth: internal.itemWidth + internal.evenlyDistributedWidth

    QtObject {
        id: internal

        property real itemWidth: Math.min(root.width, root.minimumItemWidth)
        property real totalItemsWidth: root.numItemsInRow * itemWidth
        property real remaindedWidth: root.width - totalItemsWidth
        property real evenlyDistributedWidth: Math.max(remaindedWidth / root.numItemsInRow, 0)
    }
}
