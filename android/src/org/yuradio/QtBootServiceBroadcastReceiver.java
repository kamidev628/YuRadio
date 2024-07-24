package org.yuradio;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class QtBootServiceBroadcastReceiver extends BroadcastReceiver {
  @Override
  public void onReceive(Context context, Intent intent) {
    Intent startServiceIntent = new Intent(context, MediaPlayerService.class);
    context.startService(startServiceIntent);
  }
}
