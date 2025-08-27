package com.example.smarttelemed_v4

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.annotation.NonNull
import com.example.smarttelemed_v4.CardReader
import android.webkit.PermissionRequest
import android.content.pm.PackageManager
import android.content.Intent
import android.net.Uri

class MainActivity : FlutterActivity() {

    private val CHANNEL = "esm.flutter.dev/idcard"
    private val reader: CardReader
    private var pendingWebViewPermissionRequest: PermissionRequest? = null

    init {
        reader = CardReader(this)
    }

    fun setPendingWebViewPermissionRequest(request: PermissionRequest) {
        pendingWebViewPermissionRequest = request
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        // Handle WebView permission results
        pendingWebViewPermissionRequest?.let { request ->
            val webPermissions = mutableListOf<String>()
            
            for (i in permissions.indices) {
                if (grantResults[i] == PackageManager.PERMISSION_GRANTED) {
                    when (permissions[i]) {
                        android.Manifest.permission.CAMERA -> {
                            if (request.resources.contains(PermissionRequest.RESOURCE_VIDEO_CAPTURE)) {
                                webPermissions.add(PermissionRequest.RESOURCE_VIDEO_CAPTURE)
                            }
                        }
                        android.Manifest.permission.RECORD_AUDIO -> {
                            if (request.resources.contains(PermissionRequest.RESOURCE_AUDIO_CAPTURE)) {
                                webPermissions.add(PermissionRequest.RESOURCE_AUDIO_CAPTURE)
                            }
                        }
                    }
                }
            }
            
            if (webPermissions.isNotEmpty()) {
                request.grant(webPermissions.toTypedArray())
            } else {
                request.deny()
            }
            
            pendingWebViewPermissionRequest = null
        }
    }
    private fun initReader(): Int {
        val result: Int

        reader.init()

        result = 99;

        return result
    }

    private fun read(): String {
        val result: String

        reader.read();

        result = "3840100269238";
        NativeMethodChannel.showNewIdea("3840100269238");
        return result
    }


    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NativeMethodChannel.configureChannel(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            // This method is invoked on the main thread.
            // TODO
            if (call.method == "init") {
                val it = initReader()
                result.success(it)

            } else
                if (call.method == "read") {
                    val it = read()
                    result.success(it)

                } else{
                    result.notImplemented()
                }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "flutter.native/helper"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getFilesDirMC" -> {
                    val path = applicationContext.filesDir.absolutePath
                    result.success(path)
                }
                else -> result.notImplemented()
            }
        }

        // Add external browser channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "smarttelemed/external_browser"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openBrowser" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(url))
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success("Browser opened successfully")
                        } catch (e: Exception) {
                            result.error("BROWSER_ERROR", "Failed to open browser: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_URL", "URL is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }


    }


}
