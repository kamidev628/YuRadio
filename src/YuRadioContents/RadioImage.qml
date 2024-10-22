import QtQuick

import YuRadioContents

Image {
    id: root

    property string targetSource
    property string fallbackSource
    property bool failed: true

    source: root.failed ? fallbackSource : targetSource

    fallbackSource: AppConfig.isDarkTheme ? "images/radio-white.png" : "images/radio.png"
    asynchronous: true

    onTargetSourceChanged: {
        failed = !targetSource;
    }

    onStatusChanged: {
        if (status == Image.Error || status == Image.Null) {
            failed = true;
        }
    }
}
