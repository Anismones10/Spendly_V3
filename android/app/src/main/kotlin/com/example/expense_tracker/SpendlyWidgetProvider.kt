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
            // Read data saved by Flutter via HomeWidget.saveWidgetData()
            val data = HomeWidgetPlugin.getData(context)

            val balance      = data.getString("total_balance",   "$0.00") ?: "$0.00"
            val todaySpent   = data.getString("today_spent",     "$0.00") ?: "$0.00"
            val yesterday    = data.getString("yesterday_spent", "$0.00") ?: "$0.00"
            val remaining    = data.getString("remaining",       "$0.00") ?: "$0.00"
            val lastUpdated  = data.getString("last_updated",    "--:-- --") ?: "--:-- --"
            val trend        = data.getInt("trend", 0)
            val budgetPct    = data.getInt("budget_pct", 0)
            val hasBudget    = data.getBoolean("has_budget", false)

            val views = RemoteViews(context.packageName, R.layout.spendly_widget)

            // ── Balance ───────────────────────────────────────────────────
            views.setTextViewText(R.id.widget_balance, balance)
            views.setTextViewText(R.id.widget_last_updated, lastUpdated)

            // ── Today's spending ──────────────────────────────────────────
            views.setTextViewText(R.id.widget_today_spent, todaySpent)
            views.setTextViewText(R.id.widget_yesterday, "vs $yesterday yesterday")

            // ── Trend arrow ───────────────────────────────────────────────
            when (trend) {
                1  -> {
                    views.setTextViewText(R.id.widget_trend, "▲")
                    views.setTextColor(R.id.widget_trend, Color.parseColor("#E57373"))
                }
                -1 -> {
                    views.setTextViewText(R.id.widget_trend, "▼")
                    views.setTextColor(R.id.widget_trend, Color.parseColor("#2ECC71"))
                }
                else -> {
                    views.setTextViewText(R.id.widget_trend, "")
                }
            }

            // ── Remaining budget ──────────────────────────────────────────
            views.setTextViewText(R.id.widget_remaining, remaining)

            // Remaining label changes based on whether budget is set
            val remainingLabel = if (hasBudget) "Remaining Budget" else "Available Balance"
            views.setTextViewText(R.id.widget_remaining_label, remainingLabel)

            // Budget progress bar color based on usage
            views.setProgressBar(R.id.widget_budget_bar, 100, budgetPct, false)
            val barColor = when {
                budgetPct >= 100 -> "#E57373" // red = over budget
                budgetPct >= 80  -> "#FF9800" // amber = warning
                else             -> "#2ECC71" // green = ok
            }
            views.setInt(R.id.widget_budget_bar, "setProgressTintList",
                    android.content.res.ColorStateList.valueOf(
                            Color.parseColor(barColor)).defaultColor)

            // Remaining text color matches bar
            views.setTextColor(R.id.widget_remaining, Color.parseColor(barColor))

            // ── Add Expense button — opens app to AddExpenseScreen ────────
            val addIntent = Intent(Intent.ACTION_VIEW).apply {
                setData(Uri.parse("spendly://add_expense"))
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            val addPending = PendingIntent.getActivity(
                    context, 0, addIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_add_btn, addPending)

            // ── Tap anywhere else → open app ──────────────────────────────
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
        }
    }
}