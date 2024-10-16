pragma Singleton

import QtQuick
import Main
import YuRadioContents

RadioPlayer {
    id: root

    property radiostation currentItem
    property string stationName

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

    audioStreamRecorder: AudioStreamRecorder {
        stationName: root.stationName

        recordingPolicy: AppSettings.recordingPolicy
        recordingNameFormat: AppSettings.recordingNameFormat

        outputLocation: AppSettings.recordingsDirectory

        onOutputLocationChanged: {
            AppSettings.recordingsDirectory = outputLocation;
        }
    }

    onCurrentItemChanged: {
        if (audioStreamRecorder.recording) {
            audioStreamRecorder.stop();
            audioStreamRecorder.record();
        }
        stationName = currentItem.name;
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
