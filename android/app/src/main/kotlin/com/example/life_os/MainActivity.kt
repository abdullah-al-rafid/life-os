package com.example.life_os

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.TimeZone

class MainActivity : FlutterActivity() {
    private val timezoneChannel = "life_os/device_timezone"

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
    }
}
