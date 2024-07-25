package org.yuradio;

import android.os.Handler;
import android.util.Log;

import androidx.media3.common.MediaItem;
import androidx.media3.common.MediaMetadata;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.common.Player.Listener;
import androidx.media3.session.MediaController;

public class NativeMediaController {
    private static final String TAG = NativeMediaController.class.getSimpleName();
    MediaController controller = null;
    String mediaSource = "";

    private static class PlaybackState {
        final static int Playing = 0;
        final static int Stopped = 1;
        final static int Paused = 2;
    }

    NativeMediaController() {
    }

    native public void onIsLoadingChangedNative(boolean isLoading);

    native public void onIsPlayingChangedNative(boolean isPlaying);

    native public void onPlaybackStateChangedNative(int playbackState);

    native public void onMediaTitleChangedNative(String title);

    native public void onPlayerErrorChangedNative(int errorCode, String message);

    private void setPlaybackStateNative() {
        if (controller.isPlaying()) {
            onPlaybackStateChangedNative(PlaybackState.Playing);
        } else if (!controller.getPlayWhenReady()) {
            onPlaybackStateChangedNative(PlaybackState.Paused);
        } else {
            onPlaybackStateChangedNative(PlaybackState.Stopped);
        }
    }

    public void setController(MediaController controller) {
        this.controller = controller;

        new Handler(controller.getApplicationLooper()).post(new Runnable() {
            @Override
            public void run() {
                MediaMetadata mediaMetadata = controller.getMediaMetadata();
                if (mediaMetadata.title != null) {
                    onMediaTitleChangedNative((String) mediaMetadata.title);
                }

                setPlaybackStateNative();
                onIsPlayingChangedNative(controller.isPlaying());
                onIsLoadingChangedNative(controller.isLoading());

                PlaybackException error = controller.getPlayerError();
                if (error != null) {
                    onPlayerErrorChangedNative(error.errorCode, error.getMessage());
                }
            }
        });

        controller.addListener(new Listener() {
            @Override
            public void onMediaMetadataChanged(MediaMetadata mediaMetadata) {
                if (mediaMetadata.title != null) {
                    Log.i(TAG, "StreamTitle: " + mediaMetadata.title);
                    onMediaTitleChangedNative((String) mediaMetadata.title);
                }
                Listener.super.onMediaMetadataChanged(mediaMetadata);
            }

            @Override
            public void onIsLoadingChanged(boolean isLoading) {
                Log.i(TAG, "Loading? " + isLoading);
                onIsLoadingChangedNative(isLoading);
                Listener.super.onIsLoadingChanged(isLoading);
            }

            @Override
            public void onPlaybackStateChanged(int playbackState) {
                switch (playbackState) {
                    case Player.STATE_BUFFERING:
                        Log.i(TAG, "STATE_BUFFERING");
                        break;
                    case Player.STATE_ENDED:
                        Log.i(TAG, "STATE_ENDED");
                        break;
                    case Player.STATE_IDLE:
                        Log.i(TAG, "STATE_IDLE");
                        break;
                    case Player.STATE_READY:
                        Log.i(TAG, "STATE_READY");
                        break;
                }

                Listener.super.onPlaybackStateChanged(playbackState);
            }

            @Override
            public void onIsPlayingChanged(boolean isPlaying) {
                Log.i(TAG, "IsPlaying? " + isPlaying);

                setPlaybackStateNative();
                onIsPlayingChangedNative(isPlaying);
                Listener.super.onIsPlayingChanged(isPlaying);
            }

            @Override
            public void onPlayerError(PlaybackException error) {
                Log.i(TAG, "PlayerError: " + error.getMessage());

                onPlayerErrorChangedNative(error.errorCode, error.getMessage());
                Listener.super.onPlayerError(error);
            }
        });
    }

    public void setSource(String url) {
        if (controller == null) {
            return;
        }
        new Handler(controller.getApplicationLooper()).post(new Runnable() {
            @Override
            public void run() {
                mediaSource = url;

                MediaItem mediaItem = MediaItem.fromUri(url);
                controller.setMediaItem(mediaItem);
                controller.prepare();
            }
        });
    }

    public void play() {
        if (controller == null) {
            return;
        }

        new Handler(controller.getApplicationLooper()).post(new Runnable() {
            @Override
            public void run() {
                if (controller.getCurrentMediaItem() == null && !mediaSource.isEmpty()) {
                    MediaItem mediaItem = MediaItem.fromUri(mediaSource);
                    controller.setMediaItem(mediaItem);
                }
                controller.prepare();
                controller.setPlayWhenReady(true);
            }
        });
    }

    public void stop() {
        if (controller == null) {
            return;
        }

        new Handler(controller.getApplicationLooper()).post(new Runnable() {
            @Override
            public void run() {
                controller.stop();
            }
        });
    }

    public void pause() {
        if (controller == null) {
            return;
        }

        new Handler(controller.getApplicationLooper()).post(new Runnable() {
            @Override
            public void run() {
                controller.pause();
            }
        });
    }
}
