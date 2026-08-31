package io.github.xarantolus.rockit

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.floor
import org.json.JSONArray

/**
 * Draws the next few launches and subscribed events.
 *
 * Places text and nothing else. Dart writes the finished strings, because it
 * already owns the rules for them — "Tomorrow, 12:05", or "NET October 2026"
 * when the API only knows the month — and a second implementation here would
 * drift from the one in the app.
 *
 * The data arrives in [widgetData], which is home_widget's own preferences
 * file rather than the one `shared_preferences` writes; reading the latter
 * would find nothing.
 *
 * How *many* rows appear is decided here rather than in Dart, so resizing the
 * widget takes effect immediately: every row's strings are already stored, and
 * a resize only changes how many of them are drawn.
 */
class RockItWidgetProvider : HomeWidgetProvider() {

    /** One row, with its tap target already built. */
    private class Row(
        val title: String,
        val subtitle: String,
        val onTap: PendingIntent?,
    )

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            draw(context, appWidgetManager, widgetId, widgetData)
        }
    }

    /**
     * Resizing does not go through [onUpdate], and the base class does not
     * handle it, so without this a widget dragged taller keeps showing the
     * number of rows it had when it was placed.
     */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        draw(context, appWidgetManager, appWidgetId, HomeWidgetPlugin.getData(context))
    }

    private fun draw(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
    ) {
        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val sizes = reportedSizes(options)

        // Parsed once, not once per size: each row's PendingIntent is a binder
        // call into system_server, and the trees below differ only in how many
        // of the same rows they contain.
        val rows = readRows(context, widgetData)
        val empty = widgetData.getString("empty", null).orEmpty()

        // From Android 12 the launcher can be handed one tree per size and
        // picks between them itself. That matters here because a widget's
        // portrait and landscape heights differ by about half a row: with a
        // single tree the count has to suit the shorter of the two, which
        // leaves a gap in portrait where the home screen actually lives.
        val views = if (sizes != null && sizes.isNotEmpty()) {
            RemoteViews(
                sizes.associateWith { size ->
                    build(context, rows, empty, rowsFor(context, size.height))
                },
            )
        } else {
            // MIN_HEIGHT is the *lower* bound — the landscape height. Sizing
            // to it wastes some portrait space, which is the right way round:
            // the alternative clips the last row.
            build(context, rows, empty, rowsFor(context, legacyHeightDp(options)))
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    /**
     * The rows Dart last wrote.
     *
     * One JSON string rather than three preference keys per row: every
     * `saveWidgetData` ends in a synchronous `commit()` of the whole
     * preferences file, so a key per slot made a refresh 76 of them.
     */
    private fun readRows(context: Context, widgetData: SharedPreferences): List<Row> {
        val raw = widgetData.getString("rows", null).orEmpty()
        if (raw.isEmpty()) {
            return emptyList()
        }

        return try {
            val array = JSONArray(raw)

            (0 until array.length()).mapNotNull { i ->
                val item = array.optJSONObject(i) ?: return@mapNotNull null
                val title = item.optString("title")
                if (title.isEmpty()) return@mapNotNull null

                val payload = item.optString("payload")

                Row(
                    title = title,
                    subtitle = item.optString("subtitle"),
                    // The same payload a notification carries, so the app opens
                    // this launch through the deep link it already has rather
                    // than a second route in.
                    onTap = if (payload.isEmpty()) {
                        null
                    } else {
                        HomeWidgetLaunchIntent.getActivity(
                            context,
                            MainActivity::class.java,
                            Uri.parse("rockit://widget?payload=$payload"),
                        )
                    },
                )
            }
        } catch (err: Exception) {
            // A widget showing nothing is better than a launcher-side crash.
            Log.w("RockItWidget", "Could not read the widget rows", err)
            emptyList()
        }
    }

    private fun build(
        context: Context,
        rows: List<Row>,
        empty: String,
        fits: Int,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.rockit_widget)

        views.setTextViewText(R.id.widget_empty, empty)
        views.setViewVisibility(
            R.id.widget_empty,
            if (empty.isEmpty()) View.GONE else View.VISIBLE,
        )

        // Not redundant, however empty the container is in the layout: when the
        // launcher *reapplies* a RemoteViews onto a hierarchy it already has,
        // the addView actions below run again on the children still there and
        // append a second copy of the list. It shows up as the first launch
        // repeating at the bottom, half clipped.
        views.removeAllViews(R.id.widget_rows)

        rows.take(fits).forEach { row ->
            val view = RemoteViews(context.packageName, R.layout.rockit_widget_row)
            view.setTextViewText(R.id.row_title, row.title)
            view.setTextViewText(R.id.row_subtitle, row.subtitle)
            row.onTap?.let { view.setOnClickPendingIntent(R.id.row_root, it) }

            views.addView(R.id.widget_rows, view)
        }

        // Tapping anywhere else just opens the app.
        views.setOnClickPendingIntent(
            R.id.widget_header,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )

        return views
    }

    /**
     * How many whole rows fit in [heightDp].
     *
     * Everything is measured in pixels because [android.content.res.Resources.getDimension]
     * applies the user's font scale to sp and not to dp, so a large-text
     * device gets fewer rows rather than a clipped last one. Rounding down is
     * the point: a row that only half fits is worse than the space it would
     * have taken, because the widget does not scroll.
     */
    private fun rowsFor(context: Context, heightDp: Float?): Int {
        if (heightDp == null || heightDp <= 0f) {
            return DEFAULT_ROWS
        }

        val res = context.resources
        val available = heightDp * res.displayMetrics.density -
            2 * res.getDimension(R.dimen.widget_padding) -
            res.getDimension(R.dimen.widget_header_block)

        val perRow = res.getDimension(R.dimen.widget_row_text) +
            2 * res.getDimension(R.dimen.widget_row_padding)

        return floor(available / perRow).toInt().coerceAtLeast(1)
    }

    @Suppress("DEPRECATION")
    private fun reportedSizes(options: Bundle): List<SizeF>? = when {
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU ->
            options.getParcelableArrayList(
                AppWidgetManager.OPTION_APPWIDGET_SIZES,
                SizeF::class.java,
            )

        Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
            options.getParcelableArrayList(AppWidgetManager.OPTION_APPWIDGET_SIZES)

        else -> null
    }

    private fun legacyHeightDp(options: Bundle): Float? {
        val min = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)

        return if (min > 0) min.toFloat() else null
    }

    private companion object {
        /**
         * Used only when the launcher says nothing about the size, which is
         * what the very first draw after placement can look like.
         */
        const val DEFAULT_ROWS = 3
    }
}
