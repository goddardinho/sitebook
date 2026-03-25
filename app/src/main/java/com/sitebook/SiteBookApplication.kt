package com.sitebook

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import androidx.hilt.work.HiltWorkerFactory
import androidx.work.Configuration
import androidx.work.WorkManager
import com.jakewharton.threetenabp.AndroidThreeTen
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject

@HiltAndroidApp
class SiteBookApplication : Application(), Configuration.Provider {

    @Inject
    lateinit var workerFactory: HiltWorkerFactory

    override fun onCreate() {
        super.onCreate()
        
        // Initialize ThreeTenABP for better date/time handling
        AndroidThreeTen.init(this)
        
        // Create notification channels
        createNotificationChannels()
        
        // Initialize WorkManager
        WorkManager.initialize(this, workManagerConfiguration)
    }

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setWorkerFactory(workerFactory)
            .build()

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)
            
            // Availability notifications
            val availabilityChannel = NotificationChannel(
                AVAILABILITY_CHANNEL_ID,
                "Campsite Availability",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications when monitored campsites become available"
                enableVibration(true)
                setShowBadge(true)
            }
            
            // Reservation updates
            val reservationChannel = NotificationChannel(
                RESERVATION_CHANNEL_ID,
                "Reservation Updates",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Updates about your reservations"
                enableVibration(false)
                setShowBadge(true)
            }
            
            // System notifications
            val systemChannel = NotificationChannel(
                SYSTEM_CHANNEL_ID,
                "System Notifications",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "System status and monitoring updates"
                enableVibration(false)
                setShowBadge(false)
            }

            // Monitoring service
            val monitoringChannel = NotificationChannel(
                MONITORING_CHANNEL_ID,
                "Background Monitoring",
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Background service monitoring campsite availability"
                enableVibration(false)
                setShowBadge(false)
            }
            
            notificationManager.createNotificationChannels(listOf(
                availabilityChannel,
                reservationChannel,
                systemChannel,
                monitoringChannel
            ))
        }
    }

    companion object {
        const val AVAILABILITY_CHANNEL_ID = "availability_notifications"
        const val RESERVATION_CHANNEL_ID = "reservation_notifications"
        const val SYSTEM_CHANNEL_ID = "system_notifications"
        const val MONITORING_CHANNEL_ID = "monitoring_service"
        
        // WorkManager tags
        const val AVAILABILITY_CHECK_WORK = "availability_check"
        const val RESERVATION_SYNC_WORK = "reservation_sync"
        const val CLEANUP_WORK = "cleanup_work"
    }
}