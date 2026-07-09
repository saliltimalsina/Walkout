package com.walkout.walkout.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import com.walkout.walkout.MainActivity
import com.walkout.walkout.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

/**
 * The Living Widget (4x2): a Flutter-prerendered face PNG plus a native
 * Chronometer overlay that counts down to the main card inside the final
 * 24h — live ticking with zero refresh cost.
 */
class LivingWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val imagePath = prefs.getString("living_png", null)
        val deeplink = prefs.getString("living_deeplink", "walkout://home")
        val showChrono = prefs.getBoolean("living_show_chrono", false)
        val targetMs = prefs.getLong("living_target_ms", 0L)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_living)

            var showedImage = false
            imagePath?.let { path ->
                val file = File(path)
                if (file.exists()) {
                    BitmapFactory.decodeFile(file.absolutePath)?.let {
                        views.setImageViewBitmap(R.id.living_image, it)
                        showedImage = true
                    }
                }
            }
            views.setViewVisibility(
                R.id.living_placeholder,
                if (showedImage) View.GONE else View.VISIBLE,
            )

            if (showChrono && targetMs > System.currentTimeMillis()) {
                // Chronometer uses elapsedRealtime; convert the wall-clock
                // target into an elapsed base.
                val base = SystemClock.elapsedRealtime() +
                    (targetMs - System.currentTimeMillis())
                views.setChronometer(R.id.living_chrono, base, null, true)
                views.setBoolean(R.id.living_chrono, "setCountDown", true)
                views.setViewVisibility(R.id.living_chrono, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.living_chrono, View.GONE)
            }

            val intent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse(deeplink),
            )
            views.setOnClickPendingIntent(R.id.living_root, intent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
