package com.dragostimetoshine.steps

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.aggregate.AggregateRequest
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.time.TimeRangeFilter
import java.time.Instant

/**
 * Health Connect implementation used by the future Godot Android plugin.
 *
 * This class deliberately contains no Godot code. The plugin wrapper should call it from
 * a coroutine and forward the result through the StepCounterPlugin bridge documented in
 * native/README.md.
 */
class StepHealthProvider(context: Context) {
    companion object {
        val READ_PERMISSIONS = setOf(
            HealthPermission.getReadPermission(StepsRecord::class)
        )

        fun isAvailable(context: Context): Boolean =
            HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE
    }

    private val client = HealthConnectClient.getOrCreate(context)

    suspend fun hasPermission(): Boolean {
        val granted = client.permissionController.getGrantedPermissions()
        return granted.containsAll(READ_PERMISSIONS)
    }

    suspend fun stepsSince(startUnix: Long): Long {
        require(startUnix >= 0) { "startUnix must not be negative" }
        val response = client.aggregate(
            AggregateRequest(
                metrics = setOf(StepsRecord.COUNT_TOTAL),
                timeRangeFilter = TimeRangeFilter.between(
                    Instant.ofEpochSecond(startUnix),
                    Instant.now()
                )
            )
        )
        return response[StepsRecord.COUNT_TOTAL] ?: 0L
    }
}
