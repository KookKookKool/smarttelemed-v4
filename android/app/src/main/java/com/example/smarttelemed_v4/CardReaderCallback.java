package com.example.smarttelemed_v4;

import android.graphics.Bitmap;

public interface CardReaderCallback {

    void receiveResult(String text, Bitmap bitmap);

}
