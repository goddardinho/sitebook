package com.sitebook.services

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.hilt.work.HiltWorker
import androidx.work.*
import com.sitebook.R
import com.sitebook.SiteBookApplication
import com.sitebook.data.ReservationRepository
import com.sitebook.data.local.entities.ReservationStatus
import com.sitebook.ui.MainActivity
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.*
import java.util.concurrent.TimeUnit
import javax.inject.Inject

@AndroidEntryPoint
class ReservationMonitorService : Service() {

    @Inject
    lateinit var reservationRepository: ReservationRepository

    private val serviceScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var isMonitoring = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_MONITORING -> startMonitoring()
            ACTION_STOP_MONITORING -> stopMonitoring()
        }
        return START_STICKY
    }

    private fun startMonitoring() {
        if (isMonitoring) return

        isMonitoring = true
        startForeground(NOTIFICATION_ID, createServiceNotification())

        serviceScope.launch {
            while (isMonitoring) {
                try {
                    checkAllMonitoredReservations()
                } catch (e: Exception) {
                    // Log error but continue monitoring
                }
                delay(TimeUnit.MINUTES.toMillis(5)) // Check every 5 minutes
            }
        }
    }

    private fun stopMonitoring() {
        isMonitoring = false
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private suspend fun checkAllMonitoredReservations() {
        val activeReservations = reservationRepository.getActiveMonitoringReservations()

        for (reservation in activeReservations) {
            val availability = reservationRepository.checkAvailability(
                reservation.campsiteId,
                reservation.checkInDate,
                reservation.checkOutDate
            )

            availability.onSuccess { check ->
                if (check.isAvailable) {
                    // Site is available!
                    if (reservation.autoReserve) {
                        // Attempt automatic reservation
                        attemptAutoReservation(reservation.id)
                    } else {
                        // Send notification to user
                        sendAvailabilityNotification(reservation)
                    }
                }
            }
        }
    }

    private suspend fun attemptAutoReservation(reservationId: String) {
        // TODO: Implement automatic reservation logic
        // This would integrate with the actual reservation system
        reservationRepository.updateReservationStatus(
            reservationId,
            ReservationStatus.PENDING
        )
    }

    private fun sendAvailabilityNotification(reservation: com.sitebook.data.local.entities.Reservation) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("reservation_id", reservation.id)
        }

        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, SiteBookApplication.AVAILABILITY_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Campsite Available!")
            .setContentText("Your monitored campsite is now available for booking")
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .addAction(
                R.drawable.ic_book_now,
                "Book Now",
                createBookNowIntent(reservation.id)
            )
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(reservation.id.hashCode(), notification)
    }

    private fun createBookNowIntent(reservationId: String): PendingIntent {
        val intent = Intent(this, NotificationActionReceiver::class.java).apply {
            action = NotificationActionReceiver.ACTION_BOOK_NOW
            putExtra("reservation_id", reservationId)
        }

        return PendingIntent.getBroadcast(
            this,
            reservationId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun createServiceNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, SiteBookApplication.MONITORING_CHANNEL_ID)
            .setContentTitle("SiteBook Monitoring")
            .setContentText("Monitoring campsite availability")
            .setSmallIcon(R.drawable.ic_notification)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        super.onDestroy()
        isMonitoring = false
        serviceScope.cancel()
    }

    companion object {
        const val ACTION_START_MONITORING = "START_MONITORING"
        const val ACTION_STOP_MONITORING = "STOP_MONITORING"
        private const val NOTIFICATION_ID = 1001

        fun startService(context: Context) {
            val intent = Intent(context, ReservationMonitorService::class.java).apply {
                action = ACTION_START_MONITORING
            }
            context.startForegroundService(intent)
        }

        fun stopService(context: Context) {
            val intent = Intent(context, ReservationMonitorService::class.java).apply {
                action = ACTION_STOP_MONITORING
            }
            context.startService(intent)
        }
    }
}

// WorkManager Worker for periodic availability checks
@HiltWorker
class AvailabilityCheckWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted params: WorkerParameters,
    private val reservationRepository: ReservationRepository
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            val activeReservations = reservationRepository.getActiveMonitoringReservations()

            for (reservation in activeReservations) {
                reservationRepository.checkAvailability(
                    reservation.campsiteId,
                    reservation.checkInDate,
                    reservation.checkOutDate
                )
            }

            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    companion object {
        fun schedulePeriodicCheck(context: Context) {
            val workRequest = PeriodicWorkRequestBuilder<AvailabilityCheckWorker>(
                15, TimeUnit.MINUTES
            )
                .setConstraints(
                    Constraints.Builder()
                        .setRequiredNetworkType(NetworkType.CONNECTED)
                        .build()
                )
                .addTag(SiteBookApplication.AVAILABILITY_CHECK_WORK)
                .build()

            WorkManager.getInstance(context)
                .enqueueUniquePeriodicWork(
                    SiteBookApplication.AVAILABILITY_CHECK_WORK,
                    ExistingPeriodicWorkPolicy.KEEP,
                    workRequest
                )
        }
    }
}

// Boot receiver to restart monitoring after device restart
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Restart availability checking
            AvailabilityCheckWorker.schedulePeriodicCheck(context)
        }
    }
}

// Notification action receiver
class NotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_BOOK_NOW -> {
                val reservationId = intent.getStringExtra("reservation_id")
                // Launch booking flow
                val bookingIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                    putExtra("action", "book_now")
                    putExtra("reservation_id", reservationId)
                }
                context.startActivity(bookingIntent)
            }
        }
    }

    companion object {
        const val ACTION_BOOK_NOW = "BOOK_NOW"
    }
}