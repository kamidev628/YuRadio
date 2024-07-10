package org.yuradio;

import android.app.Activity;

public class AppActivity extends org.qtproject.qt.android.bindings.QtActivity
{
    public AppActivity()
    {
        VirtualKeyboardListener.Init(this);
    }
}
