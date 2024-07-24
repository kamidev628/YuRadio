package org.yuradio;

import android.content.Intent;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.media3.common.Player;
import androidx.media3.exoplayer.ExoPlayer;
import androidx.media3.session.MediaSession;
import androidx.media3.session.MediaSessionService;

public class MediaPlayerService extends MediaSessionService {
    private static final String TAG = MediaPlayerService.class.getSimpleName();
    MediaSession mediaSession = null;

    @Nullable
    @Override
    public MediaSession onGetSession(MediaSession.ControllerInfo controllerInfo) {
        return mediaSession;
    }

    @Override
    public void onCreate() {
        super.onCreate();

        ExoPlayer player = new ExoPlayer.Builder(this).build();
        mediaSession = new MediaSession.Builder(this, player).build();

        Log.i(TAG, "Created Service");
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        Log.i(TAG, "Removing task");

        Player player = mediaSession.getPlayer();
        if (!player.getPlayWhenReady() || player.getMediaItemCount() == 0 ||
                player.getPlaybackState() == Player.STATE_ENDED) {
            stopSelf();
        }
    }

    @Override
    public void onDestroy() {
        Log.i(TAG, "Destroying Service");
        mediaSession.getPlayer().release();
        mediaSession.release();
        mediaSession = null;

        super.onDestroy();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return super.onStartCommand(intent, flags, startId);
    }
}
