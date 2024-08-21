import QtQuick
import QtQuick.Controls

Image {
    id: root
    property string targetSource
    property string fallbackSource

    property bool failed: true

    source: root.failed ? fallbackSource : targetSource

    asynchronous: true

    onTargetSourceChanged: {
        failed = !targetSource
    }

    onStatusChanged: {
        if (status == Image.Error || status == Image.Null) {
            failed = true;
        }
    }
}
