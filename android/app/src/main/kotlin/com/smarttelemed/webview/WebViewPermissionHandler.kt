package com.smarttelemed.webview

import android.webkit.PermissionRequest
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.util.Log

class WebViewPermissionHandler : WebChromeClient() {
    
    companion object {
        private const val TAG = "WebViewPermissions"
    }
    
    override fun onPermissionRequest(request: PermissionRequest) {
        Log.d(TAG, "WebView permission request: ${request.resources.joinToString()}")
        
        // Grant all requested permissions automatically since we already have native permissions
        val requestedPermissions = request.resources
        val supportedPermissions = mutableListOf<String>()
        
        // Check and grant camera permission
        if (requestedPermissions.contains(PermissionRequest.RESOURCE_VIDEO_CAPTURE)) {
            supportedPermissions.add(PermissionRequest.RESOURCE_VIDEO_CAPTURE)
            Log.d(TAG, "Granting camera permission to WebView")
        }
        
        // Check and grant microphone permission
        if (requestedPermissions.contains(PermissionRequest.RESOURCE_AUDIO_CAPTURE)) {
            supportedPermissions.add(PermissionRequest.RESOURCE_AUDIO_CAPTURE)
            Log.d(TAG, "Granting microphone permission to WebView")
        }
        
        // Grant the permissions
        if (supportedPermissions.isNotEmpty()) {
            request.grant(supportedPermissions.toTypedArray())
            Log.d(TAG, "WebView permissions granted: ${supportedPermissions.joinToString()}")
        } else {
            request.deny()
            Log.w(TAG, "No supported permissions found, denying request")
        }
    }
}
