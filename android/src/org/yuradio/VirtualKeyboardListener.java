package org.yuradio;

import android.app.Activity;
import android.graphics.Rect;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;

public class VirtualKeyboardListener {
    private Activity activity;

    public void install(Activity activity) {
        this.activity = activity;
        InstallKeyboardListener();
    }

    public native void VirtualKeyboardStateChanged(int VirtualKeyboardHeight);

    private void InstallKeyboardListener() {
        final View AppRootView = ((ViewGroup) activity.findViewById(android.R.id.content)).getChildAt(0);

        AppRootView.getViewTreeObserver().addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
            @Override
            public void onGlobalLayout() {
                int ScreenHeight, VirtualKeyboardHeight;
                Rect WindowFrameRect = new Rect();
                Rect ContentFrameRect = new Rect();

                activity.getWindow().getDecorView().getWindowVisibleDisplayFrame(WindowFrameRect);
                AppRootView.getWindowVisibleDisplayFrame(ContentFrameRect);
                ScreenHeight = AppRootView.getRootView().getHeight();

                VirtualKeyboardHeight = (ScreenHeight - (ContentFrameRect.bottom - ContentFrameRect.top) - WindowFrameRect.top);

                if (VirtualKeyboardHeight < 100) VirtualKeyboardHeight = 0;

                VirtualKeyboardStateChanged(VirtualKeyboardHeight);
            }
        });
    }
}
