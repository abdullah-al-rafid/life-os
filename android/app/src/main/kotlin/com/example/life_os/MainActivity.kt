package com.example.life_os

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Intent
import android.os.Process
import android.os.Build
import android.provider.Settings
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val timezoneChannel = "life_os/device_timezone"
    private val usageChannel = "life_os/usage_stats"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, timezoneChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "getTimeZone") {
                    val id = TimeZone.getDefault().id
                    val isNamedTimezone = id == "UTC" || id == "GMT" || id.contains("/")
                    if (isNamedTimezone && TimeZone.getAvailableIDs().contains(id)) {
                        result.success(id)
                    } else {
                        result.error(
                            "unsupported_timezone",
                            "The system timezone is not a supported IANA timezone ID.",
                            null
                        )
                    }
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, usageChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasUsageAccess" -> result.success(hasUsageAccess())
                    "openUsageSettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                            result.success(null)
                        } catch (error: Exception) {
                            result.error("usage_settings_unavailable", "Android Usage Access settings could not be opened.", null)
                        }
                    }
                    "queryUsage" -> {
                        if (!hasUsageAccess()) {
                            result.error("usage_access_denied", "Grant Usage Access in Android settings first.", null)
                        } else {
                            try {
                                val start = call.argument<Number>("startMillis")?.toLong()
                                val end = call.argument<Number>("endMillis")?.toLong()
                                if (start == null || end == null || start >= end) {
                                    result.error("invalid_usage_range", "The requested date range is invalid.", null)
                                } else {
                                    val manager = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
                                    val stats = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                                        manager.queryAndAggregateUsageStats(start, end).values.toList()
                                    } else {
                                        manager.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, start, end)
                                    }
                                    val rows = stats.groupBy { it.packageName }
                                        .map { (packageName, usageRecords) ->
                                            val foregroundMillis = usageRecords.sumOf { it.totalTimeInForeground }
                                            val label = try {
                                                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                                                packageManager.getApplicationLabel(appInfo).toString()
                                            } catch (error: Exception) {
                                                packageName
                                            }
                                            mapOf(
                                                "packageName" to packageName,
                                                "label" to label,
                                                "durationMinutes" to (foregroundMillis / 60_000L).toInt()
                                            )
                                        }
                                        .filter { (it["durationMinutes"] as Int) > 0 }
                                    result.success(rows)
                                }
                            } catch (error: Exception) {
                                result.error("usage_query_failed", "Android could not read app usage for that date.", null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(APP_OPS_SERVICE) as AppOpsManager
        return appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        ) == AppOpsManager.MODE_ALLOWED
    }
}
