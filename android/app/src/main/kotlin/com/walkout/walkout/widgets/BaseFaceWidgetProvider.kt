package com.walkout.walkout.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.walkout.walkout.MainActivity
import com.walkout.walkout.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

/**
 * Shared provider for all image-face widgets: shows `<key>_png` and deep-links
 * to `<key>_deeplink`. Each concrete widget is a two-line subclass.
 */
abstract class BaseFaceWidgetProvider(private val key: String) :
    AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = HomeWidgetPlugin.getData(context)

        for (widgetId in appWidgetIds) {
            // A per-instance fighter pick (set by WidgetConfigActivity) prefers
            // this widget's own PNG; otherwise the shared board face is shown.
            val configured = prefs.getString("cfg_fighter_$widgetId", null) != null
            val imagePath = (if (configured) prefs.getString("${key}_w${widgetId}_png", null) else null)
                ?: prefs.getString("${key}_png", null)
            val deeplink = (if (configured) prefs.getString("${key}_w${widgetId}_deeplink", null) else null)
                ?: prefs.getString("${key}_deeplink", "walkout://home")
                ?: "walkout://home"

            val views = RemoteViews(context.packageName, R.layout.widget_face)
            var showed = false
            imagePath?.let { p ->
                val f = File(p)
                if (f.exists()) {
                    BitmapFactory.decodeFile(f.absolutePath)?.let {
                        views.setImageViewBitmap(R.id.face_image, it)
                        showed = true
                    }
                }
            }
            views.setViewVisibility(
                R.id.face_placeholder,
                if (showed) View.GONE else View.VISIBLE,
            )
            views.setOnClickPendingIntent(
                R.id.face_root,
                HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java, Uri.parse(deeplink),
                ),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
