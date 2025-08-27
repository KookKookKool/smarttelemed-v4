package com.example.smarttelemed_v4

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.webkit.PermissionRequest
import android.webkit.WebChromeClient
import android.webkit.WebView
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class WebViewPermissionHandler(private val activity: Activity) : WebChromeClient() {

    companion object {
        private const val CAMERA_PERMISSION_REQUEST_CODE = 1001
        private const val MICROPHONE_PERMISSION_REQUEST_CODE = 1002
        private const val CAMERA_AND_MIC_PERMISSION_REQUEST_CODE = 1003
    }

    override fun onPermissionRequest(request: PermissionRequest?) {
        super.onPermissionRequest(request)
        
        if (request == null) return
        
        val resources = request.resources
        val permissionsNeeded = mutableListOf<String>()
        val webPermissions = mutableListOf<String>()
        
        for (resource in resources) {
            when (resource) {
                PermissionRequest.RESOURCE_VIDEO_CAPTURE -> {
                    webPermissions.add(PermissionRequest.RESOURCE_VIDEO_CAPTURE)
                    if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) 
                        != PackageManager.PERMISSION_GRANTED) {
                        permissionsNeeded.add(Manifest.permission.CAMERA)
                    }
                }
                PermissionRequest.RESOURCE_AUDIO_CAPTURE -> {
                    webPermissions.add(PermissionRequest.RESOURCE_AUDIO_CAPTURE)
                    if (ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO)
                        != PackageManager.PERMISSION_GRANTED) {
                        permissionsNeeded.add(Manifest.permission.RECORD_AUDIO)
                    }
                }
            }
        }
        
        if (permissionsNeeded.isNotEmpty()) {
            // Request Android permissions first
            val requestCode = when {
                permissionsNeeded.contains(Manifest.permission.CAMERA) && 
                permissionsNeeded.contains(Manifest.permission.RECORD_AUDIO) -> 
                    CAMERA_AND_MIC_PERMISSION_REQUEST_CODE
                permissionsNeeded.contains(Manifest.permission.CAMERA) -> 
                    CAMERA_PERMISSION_REQUEST_CODE
                else -> MICROPHONE_PERMISSION_REQUEST_CODE
            }
            
            ActivityCompat.requestPermissions(
                activity,
                permissionsNeeded.toTypedArray(),
                requestCode
            )
            
            // Store the request for later
            (activity as? MainActivity)?.setPendingWebViewPermissionRequest(request)
        } else {
            // All permissions already granted, grant web permissions
            request.grant(webPermissions.toTypedArray())
        }
    }
    
    fun handlePermissionResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
        pendingRequest: PermissionRequest?
    ) {
        if (pendingRequest == null) return
        
        when (requestCode) {
            CAMERA_PERMISSION_REQUEST_CODE,
            MICROPHONE_PERMISSION_REQUEST_CODE,
            CAMERA_AND_MIC_PERMISSION_REQUEST_CODE -> {
                val webPermissions = mutableListOf<String>()
                val resources = pendingRequest.resources
                
                for (i in permissions.indices) {
                    if (grantResults[i] == PackageManager.PERMISSION_GRANTED) {
                        when (permissions[i]) {
                            Manifest.permission.CAMERA -> {
                                if (resources.contains(PermissionRequest.RESOURCE_VIDEO_CAPTURE)) {
                                    webPermissions.add(PermissionRequest.RESOURCE_VIDEO_CAPTURE)
                                }
                            }
                            Manifest.permission.RECORD_AUDIO -> {
                                if (resources.contains(PermissionRequest.RESOURCE_AUDIO_CAPTURE)) {
                                    webPermissions.add(PermissionRequest.RESOURCE_AUDIO_CAPTURE)
                                }
                            }
                        }
                    }
                }
                
                if (webPermissions.isNotEmpty()) {
                    pendingRequest.grant(webPermissions.toTypedArray())
                } else {
                    pendingRequest.deny()
                }
            }
        }
    }
}
