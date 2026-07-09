package com.walkout.walkout.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import android.widget.RemoteViews
import com.walkout.walkout.MainActivity
import com.walkout.walkout.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.io.File

/**
 * Face-Off 4x4: a single pre-rendered PNG poster (Flutter renders it with the
 * full brand treatment) plus one tap target deep-linking into the event.
 */
class FaceoffWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val imagePath = prefs.getString("faceoff_png", null)
        val deeplink = prefs.getString("faceoff_deeplink", "walkout://home")

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_faceoff)

            var showedImage = false
            if (imagePath != null) {
                val file = File(imagePath)
                if (file.exists()) {
                    // Bound decode size: RemoteViews bitmaps have a transport
                    // budget; the source is already sized for the cell.
                    val opts = BitmapFactory.Options().apply { inSampleSize = 1 }
                    BitmapFactory.decodeFile(file.absolutePath, opts)?.let {
                        views.setImageViewBitmap(R.id.faceoff_image, it)
                        showedImage = true
                    }
                }
            }
            views.setViewVisibility(
                R.id.faceoff_placeholder,
                if (showedImage) android.view.View.GONE else android.view.View.VISIBLE,
            )

            val intent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse(deeplink),
            )
            views.setOnClickPendingIntent(R.id.faceoff_root, intent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
