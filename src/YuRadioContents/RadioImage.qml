import QtQuick
import QtQuick.Controls

Image {
    property string targetSource
    property string fallbackSource

    function handleChange() {
        if (targetSource) {
            source = Qt.binding(() => targetSource);
        } else if (fallbackSource) {
            source = Qt.binding(() => fallbackSource);
        }
    }

    onTargetSourceChanged: {
        handleChange();
    }

    onFallbackSourceChanged: {
        handleChange();
    }

    onStatusChanged: {
        if (status == Image.Error) {
            source = Qt.binding(() => fallbackSource);
        }
    }
}
