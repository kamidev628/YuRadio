package org.yuradio;

import android.content.ComponentName;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.media3.session.MediaController;
import androidx.media3.session.SessionToken;

import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.MoreExecutors;

import org.qtproject.qt.android.bindings.QtActivity;

import java.util.concurrent.ExecutionException;

public class MediaPlayerActivity extends QtActivity {
    private static final String TAG = MediaPlayerActivity.class.getSimpleName();

    private MediaController controller = null;
    private ListenableFuture<MediaController> controllerFuture;
    private NativeMediaController nativeMediaController = null;

    public void registerNativeMediaController(NativeMediaController mediaController) {
        nativeMediaController = mediaController;

        if (controller != null) {
            nativeMediaController.setController(controller);
        }
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        Log.i(TAG, "Create");
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onStart() {
        super.onStart();

        SessionToken sessionToken = new SessionToken(this, new ComponentName(this, MediaPlayerService.class));

        controllerFuture = new MediaController.Builder(this, sessionToken).buildAsync();
        controllerFuture.addListener(() -> {
            try {
                controller = controllerFuture.get();

                if (nativeMediaController != null) {
                    nativeMediaController.setController(controller);
                }
            } catch (ExecutionException | InterruptedException e) {
                throw new RuntimeException(e);
            }
        }, MoreExecutors.directExecutor());
    }

    @Override
    public void onStop() {
        Log.i(TAG, "Stop");
        super.onStop();
    }

    @Override
    public void onDestroy() {
        Log.i(TAG, "Destroyed");
        MediaController.releaseFuture(controllerFuture);
        super.onDestroy();
    }
}
