package com.fshangala.apps.glossa_messenger

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class SmsReceiver : BroadcastReceiver() {
    private val CHANNEL = "com.fshangala.apps.glossa_messenger/sms"
    private val NOTIFICATION_CHANNEL_ID = "glossa_sms_alerts"

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_DELIVER_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            
            if (messages.isNotEmpty()) {
                val smsAddress = messages[0].displayOriginatingAddress ?: "Unknown Sender"
                val bodyBuilder = StringBuilder()
                for (msg in messages) {
                    bodyBuilder.append(msg.displayMessageBody)
                }
                val smsBody = bodyBuilder.toString()
                val timestamp = System.currentTimeMillis()

                val smsData = mapOf(
                    "address" to smsAddress,
                    "body" to smsBody,
                    "timestamp" to timestamp
                )

                val flutterEngine = FlutterEngineCache.getInstance().get("glossa_messenger_engine")
                
                if (flutterEngine != null) {
                    // Scenario A: App is open. Send the payload to Dart memory
                    val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                        channel.invokeMethod("onMessageReceived", smsData)
                    }
                } else {
                    // Scenario B: App is closed/minimized. Show a high-priority system notification banner
                    showHeadsUpNotification(context, smsAddress, smsBody)
                }
            }
        }
    }

    private fun showHeadsUpNotification(context: Context, sender: String, messageBody: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // 1. Build out the mandatory Notification Channel for Android 8.0 Oreo and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "New Messages",
                NotificationManager.IMPORTANCE_HIGH // Crucial for displaying a Heads-Up pop-up banner
            ).apply {
                description = "Incoming message alerts from Glossa Messenger"
                enableLights(true)
                enableVibration(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // 2. Set intent routing so clicking the notification instantly opens the messaging app
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context, 
            0, 
            launchIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 3. Assemble the notification visual properties
        val builder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.sym_action_chat) // Temporary system messaging icon asset
            .setContentTitle(sender)
            .setContentText(messageBody)
            .setPriority(NotificationCompat.PRIORITY_HIGH) // Support legacy devices below Android Oreo
            .setCategory(NotificationCompat.CATEGORY_MESSAGE)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)

        // Unique dynamic notification handle using hashcodes to avoid overwriting unread threads
        notificationManager.notify(sender.hashCode(), builder.build())
    }
}
