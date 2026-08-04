package com.example.seungyo_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class NextGameWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        updateAll(context)
    }

    companion object {
        fun updateAll(context: Context) {
            val prefs = context.getSharedPreferences("game_companion", Context.MODE_PRIVATE)
            val opponent = prefs.getString("opponent", null)
            val date = prefs.getString("game_date", "") ?: ""
            val time = prefs.getString("game_time", "") ?: ""
            val stadium = prefs.getString("stadium", "") ?: ""
            val views = RemoteViews(context.packageName, R.layout.next_game_widget)
            views.setTextViewText(R.id.widget_matchup,
                if (opponent.isNullOrBlank()) "예정된 다음 경기가 없습니다" else "VS $opponent")
            views.setTextViewText(R.id.widget_detail, listOf(date, time, stadium)
                .filter { it.isNotBlank() }.joinToString(" · "))
            val intent = Intent(context, MainActivity::class.java)
            views.setOnClickPendingIntent(R.id.widget_matchup, PendingIntent.getActivity(
                context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, NextGameWidgetProvider::class.java)
            manager.updateAppWidget(component, views)
        }
    }
}
