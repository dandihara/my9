package com.example.seungyo_app

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun getRenderMode(): RenderMode = RenderMode.texture

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "seungyo/app_icon")
            .setMethodCallHandler { call, result ->
                if (call.method != "setTeamIcon") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val team = call.argument<String>("team")
                if (team == "doosan") {
                    setAlias("DoosanIconAlias", true)
                    setAlias("DefaultIconAlias", false)
                } else {
                    setAlias("DefaultIconAlias", true)
                    setAlias("DoosanIconAlias", false)
                }
                result.success(null)
            }
    }

    private fun setAlias(alias: String, enabled: Boolean) {
        packageManager.setComponentEnabledSetting(
            ComponentName(this, "$packageName.$alias"),
            if (enabled) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
            else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP,
        )
    }
}
