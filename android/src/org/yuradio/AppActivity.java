package org.yuradio;

import android.os.Bundle;
import android.view.View;
import android.view.ViewTreeObserver;

import androidx.media3.common.util.Log;

public class AppActivity extends MediaPlayerActivity {
    private static final String TAG = AppActivity.class.getSimpleName();

    private boolean isQmlApplicationStarted = false;

    public void qmlApplicationStarted() {
        isQmlApplicationStarted = true;
    }

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    }

    @Override
    public void onStart() {
        super.onStart();

        // Set the layout for the content view.
        final View content = findViewById(android.R.id.content);

        content.getViewTreeObserver().addOnPreDrawListener(
                new ViewTreeObserver.OnPreDrawListener() {
                    @Override
                    public boolean onPreDraw() {
                        if (isQmlApplicationStarted) {
                            Log.i(TAG, "YuRadio first frame");
                            content.getViewTreeObserver().removeOnPreDrawListener(this);
                            return true;
                        } else {
                            return false;
                        }
                    }
                });
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
