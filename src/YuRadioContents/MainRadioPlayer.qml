pragma Singleton

import QtQuick
import Main
import YuRadioContents

RadioPlayer {
    id: root

    property radiostation currentItem

    function toggleRadio() {
        if (AppSettings.pauseButtonBehaviour === "pause") {
            toggle(RadioPlayer.PlayPauseBehaviour);
        } else if (AppSettings.pauseButtonBehaviour === "stop") {
            toggle(RadioPlayer.PlayStopBehaviour);
        } else {
            console.assert(false, `Unknown option detected for "AppSettings.pauseButtonBehaviour": ${AppSettings.pauseButtonBehaviour}`);
        }
    }

    volume: AppSettings.volume
    onVolumeChanged: {
        AppSettings.volume = volume;
    }

    onCurrentItemChanged: {
        if (currentItem.isValid()) {
            const newMediaItem = constructMediaItem();
            newMediaItem.artworkUri = currentItem.favicon;
            newMediaItem.author = currentItem.name;
            newMediaItem.source = currentItem.url;
            AppSettings.stationUuid = currentItem.uuid;
            mediaItem = newMediaItem;
        } else {
            AppSettings.stationUuid = "";
        }
    }
}
