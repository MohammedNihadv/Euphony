package com.mhdni.euphony

import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity
import java.io.File
import java.io.FileInputStream

// AudioServiceActivity, not FlutterActivity: audio_service routes media button
// intents and service reconnection through it. With a plain FlutterActivity the
// notification and lock-screen controls never reach the app.
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mhdni.euphony/export").setMethodCallHandler { call, result ->
            if (call.method == "writeToContentUri") {
                val uriString = call.argument<String>("uri")
                val sourcePath = call.argument<String>("sourcePath")
                
                if (uriString != null && sourcePath != null) {
                    try {
                        val uri = Uri.parse(uriString)
                        val sourceFile = File(sourcePath)
                        contentResolver.openOutputStream(uri)?.use { outputStream ->
                            FileInputStream(sourceFile).use { inputStream ->
                                inputStream.copyTo(outputStream)
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to write to URI: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "uri or sourcePath is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
