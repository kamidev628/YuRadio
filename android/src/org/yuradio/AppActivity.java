package org.yuradio;

import android.os.Bundle;

import androidx.media3.common.util.Log;

public class AppActivity extends MediaPlayerActivity {
    private static final String TAG = AppActivity.class.getSimpleName();

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onStart() {
        super.onStart();
    }

    @Override
    public void onStop() {
        Log.i(TAG, "Stop");
        super.onStop();
    }

    @Override
    public void onDestroy() {
        Log.i(TAG, "Destroyed");
        super.onDestroy();
    }
}
