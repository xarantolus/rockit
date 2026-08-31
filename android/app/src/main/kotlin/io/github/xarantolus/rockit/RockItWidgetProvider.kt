package io.github.xarantolus.rockit

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.floor

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
 * widget takes effect immediately: all ten strings are already stored, and a
 * resize only changes how many of them are shown.
 */
class RockItWidgetProvider : HomeWidgetProvider() {

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

        // From Android 12 the launcher can be handed one tree per size and
        // picks between them itself. That matters here because a widget's
        // portrait and landscape heights differ by about half a row: with a
        // single tree the count has to suit the shorter of the two, which
        // leaves a gap in portrait where the home screen actually lives.
        val views = if (sizes != null && sizes.isNotEmpty()) {
            RemoteViews(
                sizes.associateWith { size ->
                    build(context, widgetData, rowsFor(context, size.height))
                },
            )
        } else {
            // MIN_HEIGHT is the *lower* bound — the landscape height. Sizing
            // to it wastes some portrait space, which is the right way round:
            // the alternative clips the last row.
            build(context, widgetData, rowsFor(context, legacyHeightDp(options)))
        }

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun build(
        context: Context,
        widgetData: SharedPreferences,
        rows: Int,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.rockit_widget)

        val empty = widgetData.getString("empty", null).orEmpty()
        views.setTextViewText(R.id.widget_empty, empty)
        views.setViewVisibility(
            R.id.widget_empty,
            if (empty.isEmpty()) View.GONE else View.VISIBLE,
        )

        ROWS.forEachIndexed { index, (rowId, titleId, subtitleId) ->
            val title = widgetData.getString("title_$index", null).orEmpty()
            val payload = widgetData.getString("payload_$index", null).orEmpty()

            // Hidden rather than left blank, so two upcoming launches do not
            // leave a gap where a third would have been.
            views.setViewVisibility(
                rowId,
                if (index < rows && title.isNotEmpty()) View.VISIBLE else View.GONE,
            )
            views.setTextViewText(titleId, title)
            views.setTextViewText(
                subtitleId,
                widgetData.getString("subtitle_$index", null).orEmpty(),
            )

            if (payload.isNotEmpty()) {
                // The same payload a notification carries, so the app opens
                // this launch through the deep link it already has rather
                // than a second route in.
                views.setOnClickPendingIntent(
                    rowId,
                    HomeWidgetLaunchIntent.getActivity(
                        context,
                        MainActivity::class.java,
                        Uri.parse("rockit://widget?payload=$payload"),
                    ),
                )
            }
        }

        // Tapping anywhere else just opens the app.
        views.setOnClickPendingIntent(
            R.id.widget_header,
            HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
        )

        return views
    }

    /**
     * How many rows fit in [heightDp].
     *
     * Everything is measured in pixels because [android.content.res.Resources.getDimension]
     * applies the user's font scale to sp and not to dp, so a large-text
     * device gets fewer rows rather than a clipped last one.
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
            res.getDimension(R.dimen.widget_row_spacing)

        return floor(available / perRow).toInt().coerceIn(1, ROWS.size)
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

        val ROWS = listOf(
            Triple(R.id.row_0, R.id.title_0, R.id.subtitle_0),
            Triple(R.id.row_1, R.id.title_1, R.id.subtitle_1),
            Triple(R.id.row_2, R.id.title_2, R.id.subtitle_2),
            Triple(R.id.row_3, R.id.title_3, R.id.subtitle_3),
            Triple(R.id.row_4, R.id.title_4, R.id.subtitle_4),
            Triple(R.id.row_5, R.id.title_5, R.id.subtitle_5),
            Triple(R.id.row_6, R.id.title_6, R.id.subtitle_6),
            Triple(R.id.row_7, R.id.title_7, R.id.subtitle_7),
            Triple(R.id.row_8, R.id.title_8, R.id.subtitle_8),
            Triple(R.id.row_9, R.id.title_9, R.id.subtitle_9),
        )
    }
}
