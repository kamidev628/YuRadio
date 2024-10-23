package org.yuradio;

import android.content.Context;

import android.app.Activity;
import android.graphics.Rect;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;

public class VirtualKeyboardListener {
    public native void virtualKeyboardHeightChanged(int height);

    public void install(Context context) {
        final View content = ((Activity) context).findViewById(android.R.id.content);

        content.getViewTreeObserver().addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
            @Override
            public void onGlobalLayout() {
                int screenHeight, virtualKeyboardHeight;
                Rect windowFrameRect = new Rect();
                Rect contentFrameRect = new Rect();

                ((Activity) context).getWindow().getDecorView().getWindowVisibleDisplayFrame(windowFrameRect);
                content.getWindowVisibleDisplayFrame(contentFrameRect);
                screenHeight = content.getRootView().getHeight();

                virtualKeyboardHeight = (screenHeight - (contentFrameRect.bottom - contentFrameRect.top) - windowFrameRect.top);

                if (virtualKeyboardHeight < 100) virtualKeyboardHeight = 0;

                virtualKeyboardHeightChanged(virtualKeyboardHeight);
            }
        });
    }
}
