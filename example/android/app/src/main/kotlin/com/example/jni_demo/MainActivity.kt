package com.example.jni_demo

import androidx.annotation.NonNull
import com.example.ContinuationManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example/continue"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "continue") {
                ContinuationManager.getGlobalRefFromTag(call.arguments(), result);
            } else {
                result.notImplemented()
            }
        }
    }
}
