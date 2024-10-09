package org.yuradio;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

public class StreamTitleBroadcastReceiver {
    private static final String TAG = StreamTitleBroadcastReceiver.class.getSimpleName();

    private static native void onMediaTitleChangedNative(String message);

    public static final String BROADCAST_CUSTOM_ACTION = "org.yuradio.streamtitle";

    public void registerServiceBroadcastReceiver(Context context) {
        IntentFilter intentFilter = new IntentFilter();

        intentFilter.addAction(BROADCAST_CUSTOM_ACTION);
        context.registerReceiver(serviceMessageReceiver, intentFilter);

        Log.i(TAG, "Registered broadcast receiver");
    }

    private BroadcastReceiver serviceMessageReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            Log.i(TAG, "In OnReceive()");

            if (BROADCAST_CUSTOM_ACTION.equals(intent.getAction())) {
                String streamTitle = intent.getStringExtra("streamTitle");

                onMediaTitleChangedNative(streamTitle);

                Log.i(TAG, "Message sent to c++: " + streamTitle);
            }
        }
    };
}
