package com.walkout.walkout

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

/**
 * Configuration screen shown when a fighter-subject widget (Journey, Finish
 * DNA, Radar, Momentum, Last 5, Belt) is added. Lets the user pick which
 * fighter that specific widget instance should track. The choice is stored in
 * the shared widget prefs; the Dart side renders a per-instance PNG for it on
 * the next app foreground.
 */
class WidgetConfigActivity : Activity() {

    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    // Provider class suffix -> face key used by the Dart render pipeline.
    private val classToKey = mapOf(
        "BeltsWidgetProvider" to "belts",
        "MomentumWidgetProvider" to "momentum",
        "FinishDnaWidgetProvider" to "finish_dna",
        "RadarWidgetProvider" to "radar",
        "Last5WidgetProvider" to "last5",
        "JourneyWidgetProvider" to "journey",
    )

    private data class FighterRow(val id: String, val label: String)

    private var all: List<FighterRow> = emptyList()
    private var shown: List<FighterRow> = emptyList()
    private lateinit var adapter: ArrayAdapter<String>

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // If the user backs out, the widget must not be added.
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        all = loadFighters()
        shown = all

        setContentView(buildUi())

        adapter.addAll(all.map { it.label })
        adapter.notifyDataSetChanged()
    }

    private fun key(): String? {
        val info = AppWidgetManager.getInstance(this).getAppWidgetInfo(appWidgetId)
        val cls = info?.provider?.className?.substringAfterLast('.')
        return classToKey[cls]
    }

    private fun dp(v: Int): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics,
    ).toInt()

    private fun buildUi(): View {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#0B0B0D"))
            setPadding(dp(16), dp(20), dp(16), dp(8))
        }

        val title = TextView(this).apply {
            text = "Choose a fighter"
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            gravity = Gravity.START
        }
        root.addView(title)

        val search = EditText(this).apply {
            hint = "Search fighters"
            setHintTextColor(Color.parseColor("#6E6E76"))
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#161618"))
            setPadding(dp(12), dp(12), dp(12), dp(12))
        }
        val lp = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply { topMargin = dp(12); bottomMargin = dp(8) }
        root.addView(search, lp)

        adapter = object : ArrayAdapter<String>(
            this, android.R.layout.simple_list_item_1, mutableListOf(),
        ) {
            override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                val v = super.getView(position, convertView, parent)
                (v as? TextView)?.setTextColor(Color.WHITE)
                return v
            }
        }

        val list = ListView(this).apply {
            this.adapter = this@WidgetConfigActivity.adapter
            setOnItemClickListener { _, _, position, _ ->
                shown.getOrNull(position)?.let { onPick(it.id) }
            }
        }
        root.addView(
            list,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f,
            ),
        )

        search.addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) {}
            override fun beforeTextChanged(s: CharSequence?, a: Int, b: Int, c: Int) {}
            override fun onTextChanged(s: CharSequence?, a: Int, b: Int, c: Int) {
                val q = s?.toString()?.trim()?.lowercase().orEmpty()
                shown = if (q.isEmpty()) all
                else all.filter { it.label.lowercase().contains(q) }
                adapter.clear()
                adapter.addAll(shown.map { it.label })
                adapter.notifyDataSetChanged()
            }
        })

        return root
    }

    private fun onPick(fighterId: String) {
        val prefs = HomeWidgetPlugin.getData(this)
        val faceKey = key()
        val editor = prefs.edit()
        editor.putString("cfg_fighter_$appWidgetId", fighterId)
        if (faceKey != null) editor.putString("cfg_key_$appWidgetId", faceKey)
        // Track configured ids as a comma-joined string (Dart-friendly).
        val existing = prefs.getString("cfg_ids", "").orEmpty()
        val ids = existing.split(",").filter { it.isNotEmpty() }.toMutableSet()
        ids.add(appWidgetId.toString())
        editor.putString("cfg_ids", ids.joinToString(","))
        editor.apply()

        // Show the shared face immediately (per-instance PNG renders on next
        // app foreground) so the freshly-added widget isn't blank.
        val info = AppWidgetManager.getInstance(this).getAppWidgetInfo(appWidgetId)
        info?.provider?.let { provider ->
            sendBroadcast(
                Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                    component = provider
                    putExtra(
                        AppWidgetManager.EXTRA_APPWIDGET_IDS,
                        intArrayOf(appWidgetId),
                    )
                },
            )
        }

        setResult(
            RESULT_OK,
            Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId),
        )
        finish()
    }

    private fun loadFighters(): List<FighterRow> {
        return try {
            val json = assets.open("flutter_assets/assets/data/fighters.json")
                .bufferedReader().use { it.readText() }
            val arr = JSONArray(json)
            val out = ArrayList<FighterRow>(arr.length())
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                val id = o.optString("id")
                val name = o.optString("name")
                if (id.isEmpty() || name.isEmpty()) continue
                val rec = o.optJSONObject("record")
                val record = if (rec != null) {
                    "${rec.optInt("wins")}-${rec.optInt("losses")}-${rec.optInt("draws")}"
                } else ""
                val champ = if (o.optBoolean("isChampion")) "  ·  C" else ""
                out.add(FighterRow(id, "$name    $record$champ"))
            }
            out.sortBy { it.label }
            out
        } catch (e: Exception) {
            emptyList()
        }
    }
}
