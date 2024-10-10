package org.yuradio;

import android.net.Uri;
import android.os.Handler;
import android.util.Log;
import android.webkit.URLUtil;

import androidx.media3.common.MediaItem;
import androidx.media3.common.MediaMetadata;
import androidx.media3.common.PlaybackException;
import androidx.media3.common.Player;
import androidx.media3.common.Player.Listener;
import androidx.media3.session.MediaController;

import com.google.common.base.Strings;

public class NativeMediaController {
    private static final String TAG = NativeMediaController.class.getSimpleName();

    private AppActivity activity;
    private MediaController controller = null;
    private String mediaSource = "";
    private String mediaAuthor;
    private String artworkUri;

    private static class PlaybackState {
        final static int Playing = 0;
        final static int Stopped = 1;
        final static int Paused = 2;
    }

    NativeMediaController() {
    }

    native public void onMediaTitleChangedNative(String title);

    native public void onIsLoadingChangedNative(boolean isLoading);

    native public void onIsPlayingChangedNative(boolean isPlaying);

    native public void onPlaybackStateChangedNative(int playbackState);

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

    public void setActivity(AppActivity activity) {
        this.activity = activity;
        activity.registerNativeMediaController(this);
    }

    public void setController(MediaController controller) {
        this.controller = controller;

        new Handler(controller.getApplicationLooper()).post(new Runnable() {
            @Override
            public void run() {
                MediaMetadata mediaMetadata = controller.getMediaMetadata();
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

    private MediaItem buildMediaItem() {
        Log.i(TAG, "Author: " + mediaAuthor + " ArtworkUri: " + artworkUri);

        return new MediaItem.Builder() 
                .setUri(mediaSource)
                .setMediaMetadata(new MediaMetadata.Builder()
                        .setArtist(mediaAuthor)
                        .setArtworkUri(Uri.parse(artworkUri))
                        .build())
                .build();
    }

    public void setSource(String url) {
        mediaSource = url;

        if (controller == null || !URLUtil.isValidUrl(mediaSource)) {
            return;
        }

        new Handler(controller.getApplicationLooper()).post(new Runnable() {
            @Override
            public void run() {
                MediaItem mediaItem = buildMediaItem();
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
                Log.i(TAG, "Controller Play");
                if (controller.getCurrentMediaItem() == null && !mediaSource.isEmpty()) {
                    MediaItem mediaItem = buildMediaItem();
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
                Log.i(TAG, "Controller Stop");

                controller.stop();
                // BUG: ExoPlayer doesn't `emit` onIsPlayingChanged
                onPlaybackStateChangedNative(PlaybackState.Stopped);
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
                Log.i(TAG, "Controller Pause");
                controller.pause();
            }
        });
    }

    public void setVolume(float volume) {
        if (controller == null) {
            return;
        }

        new Handler(controller.getApplicationLooper()).post(new Runnable() {
            @Override
            public void run() {
                Log.i(TAG, "Controller setVolume: " + volume);
                controller.setVolume(volume);
            }
        });
    }

    public void setArtworkUri(String artworkUri) {
        this.artworkUri = artworkUri;
    }

    public void setAuthor(String mediaAuthor) {
        this.mediaAuthor = mediaAuthor;
    }
}
