package com.example.seungyo_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

class GameReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val manager = context.getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(
                "game_reminders", "경기 알림", NotificationManager.IMPORTANCE_DEFAULT))
        }
        val open = PendingIntent.getActivity(context, 0, Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val opponent = intent.getStringExtra("opponent") ?: "상대팀"
        manager.notify(1200, NotificationCompat.Builder(context, "game_reminders")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("MY9 경기 시작 1시간 전")
            .setContentText("${opponent}전이 곧 시작합니다.")
            .setContentIntent(open).setAutoCancel(true).build())
    }
}
