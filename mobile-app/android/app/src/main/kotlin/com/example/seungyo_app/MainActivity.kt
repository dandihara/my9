package com.example.seungyo_app

import android.content.ComponentName
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.LocalDateTime
import java.time.ZoneId

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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "seungyo/game_companion")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateNextGame" -> {
                        val values = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                        val prefs = getSharedPreferences("game_companion", Context.MODE_PRIVATE)
                        prefs.edit()
                            .putString("game_date", values["gameDate"] as? String)
                            .putString("game_time", values["gameTime"] as? String)
                            .putString("opponent", values["opponent"] as? String)
                            .putString("stadium", values["stadium"] as? String)
                            .apply()
                        NextGameWidgetProvider.updateAll(this)
                        scheduleReminder(values)
                        result.success(null)
                    }
                    "setNotificationsEnabled" -> {
                        val enabled = call.argument<Boolean>("enabled") == true
                        getSharedPreferences("game_companion", Context.MODE_PRIVATE)
                            .edit().putBoolean("notifications", enabled).apply()
                        if (enabled && Build.VERSION.SDK_INT >= 33) {
                            requestPermissions(arrayOf("android.permission.POST_NOTIFICATIONS"), 1200)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun scheduleReminder(values: Map<*, *>) {
        val prefs = getSharedPreferences("game_companion", Context.MODE_PRIVATE)
        if (!prefs.getBoolean("notifications", true)) return
        val date = values["gameDate"] as? String ?: return
        val time = (values["gameTime"] as? String)?.take(5) ?: return
        val trigger = try {
            LocalDateTime.parse("${date}T${time}:00").atZone(ZoneId.systemDefault())
                .minusHours(1).toInstant().toEpochMilli()
        } catch (_: Exception) { return }
        if (trigger <= System.currentTimeMillis()) return
        val intent = Intent(this, GameReminderReceiver::class.java)
            .putExtra("opponent", values["opponent"] as? String)
        val pending = PendingIntent.getBroadcast(this, 1200, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val alarm = getSystemService(AlarmManager::class.java)
        alarm.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pending)
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
