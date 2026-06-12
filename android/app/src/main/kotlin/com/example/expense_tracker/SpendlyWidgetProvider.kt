package com.example.expense_tracker

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.graphics.Color
import android.app.PendingIntent
import es.antonborri.home_widget.HomeWidgetPlugin

class SpendlyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    companion object {
        fun updateWidget(
                context: Context,
                appWidgetManager: AppWidgetManager,
                widgetId: Int
        ) {
            try {
                val data = HomeWidgetPlugin.getData(context)

                val balance     = data.getString("total_balance",   "0.00") ?: "0.00"
                val todaySpent  = data.getString("today_spent",     "0.00") ?: "0.00"
                val yesterday   = data.getString("yesterday_spent", "0.00") ?: "0.00"
                val remaining   = data.getString("remaining",       "0.00") ?: "0.00"
                val lastUpdated = data.getString("last_updated",    "--:--") ?: "--:--"
                val trend       = data.getInt("trend", 0)
                val budgetPct   = data.getInt("budget_pct", 0)
                val hasBudget   = data.getBoolean("has_budget", false)

                val views = RemoteViews(context.packageName, R.layout.spendly_widget)

                // Balance
                views.setTextViewText(R.id.widget_balance, balance)
                views.setTextViewText(R.id.widget_last_updated, lastUpdated)

                // Today spent
                views.setTextViewText(R.id.widget_today_spent, todaySpent)
                views.setTextViewText(R.id.widget_yesterday, "vs $yesterday yesterday")

                // Trend arrow
                when (trend) {
                    1 -> {
                        views.setTextViewText(R.id.widget_trend, "▲")
                        views.setTextColor(R.id.widget_trend, Color.parseColor("#E57373"))
                    }
                    -1 -> {
                        views.setTextViewText(R.id.widget_trend, "▼")
                        views.setTextColor(R.id.widget_trend, Color.parseColor("#2ECC71"))
                    }
                    else -> views.setTextViewText(R.id.widget_trend, "")
                }

                // Remaining
                val barColor = when {
                    budgetPct >= 100 -> Color.parseColor("#E57373")
                    budgetPct >= 80  -> Color.parseColor("#FF9800")
                    else             -> Color.parseColor("#2ECC71")
                }
                views.setTextViewText(R.id.widget_remaining, remaining)
                views.setTextColor(R.id.widget_remaining, barColor)
                views.setTextViewText(
                    R.id.widget_remaining_label,
                    if (hasBudget) "Remaining Budget" else "Available Balance"
                )
                views.setProgressBar(R.id.widget_budget_bar, 100, budgetPct, false)

                // Add Expense deep link
                val addPending = PendingIntent.getActivity(
                        context, 0,
                        Intent(Intent.ACTION_VIEW, Uri.parse("spendly://add_expense")).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        },
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_add_btn, addPending)

                // Tap widget body → open app
                val openIntent = context.packageManager
                        .getLaunchIntentForPackage(context.packageName)
                        ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
                if (openIntent != null) {
                    val openPending = PendingIntent.getActivity(
                            context, 1, openIntent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    views.setOnClickPendingIntent(R.id.widget_balance, openPending)
                    views.setOnClickPendingIntent(R.id.widget_today_spent, openPending)
                    views.setOnClickPendingIntent(R.id.widget_remaining, openPending)
                }

                appWidgetManager.updateAppWidget(widgetId, views)

            } catch (e: Exception) {
                // Fallback: show minimal widget without crashing
                val views = RemoteViews(context.packageName, R.layout.spendly_widget)
                views.setTextViewText(R.id.widget_balance, "Open Spendly")
                appWidgetManager.updateAppWidget(widgetId, views)
            }
        }
    }
}
