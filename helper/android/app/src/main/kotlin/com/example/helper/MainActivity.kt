package com.example.helper

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)

        // Create notification channels for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannels()
        }
    }

    private fun createNotificationChannels() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Default channel for FCM
        val defaultChannel = NotificationChannel(
            "default",
            "Default Notifications",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Default notification channel"
            enableLights(true)
            enableVibration(true)
            setShowBadge(true)
        }

        // Reviews channel
        val reviewsChannel = NotificationChannel(
            "reviews",
            "Review Notifications",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Notifications for new reviews"
            enableLights(true)
            enableVibration(true)
            setShowBadge(true)
        }

        // Calls channel
        val callsChannel = NotificationChannel(
            "calls",
            "Call Notifications",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Notifications for incoming calls"
            enableLights(true)
            enableVibration(true)
            setShowBadge(true)
        }

        // Create the channels
        notificationManager.createNotificationChannel(defaultChannel)
        notificationManager.createNotificationChannel(reviewsChannel)
        notificationManager.createNotificationChannel(callsChannel)
    }
}
