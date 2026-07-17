package com.fshangala.apps.glossa_messenger

import android.app.RoleManager
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.fshangala.apps.glossa_messenger/sms"
    private val REQUEST_ROLE_SMS = 101

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        FlutterEngineCache.getInstance().put("glossa_messenger_engine", flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isDefaultSmsApp" -> {
                    result.success(isDefaultSmsApp())
                }
                "requestDefaultSmsApp" -> {
                    requestDefaultSmsApp()
                    result.success(true)
                }
                "getConversations" -> {
                    val conversations = getConversations()
                    result.success(conversations)
                }
                "getMessagesForThread" -> {
                    val threadId = call.argument<String>("threadId")
                    if (threadId != null) {
                        val messages = getMessagesForThread(threadId)
                        result.success(messages)
                    } else {
                        result.error("BAD_ARGUMENT", "Thread ID is required", null)
                    }
                }
                "sendSms" -> {
                    val address = call.argument<String>("address")
                    val messageBody = call.argument<String>("message")
                    
                    if (!address.isNullOrBlank() && !messageBody.isNullOrBlank()) {
                        val isSent = sendSms(address, messageBody)
                        if (isSent) {
                            result.success(true)
                        } else {
                            result.error("SEND_FAILED", "Failed to dispatch SMS payload via native manager", null)
                        }
                    } else {
                        result.error("BAD_ARGUMENTS", "Destination address and message text body cannot be empty", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // Checks if the app is currently the default handler
    private fun isDefaultSmsApp(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
            roleManager.isRoleHeld(RoleManager.ROLE_SMS)
        } else {
            val defaultSmsPackage = Telephony.Sms.getDefaultSmsPackage(this)
            defaultSmsPackage == packageName
        }
    }

    // Prompts the Android OS system dialog
    private fun requestDefaultSmsApp() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
            if (roleManager.isRoleAvailable(RoleManager.ROLE_SMS)) {
                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS)
                startActivityForResult(intent, REQUEST_ROLE_SMS)
            }
        } else {
            val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT).apply {
                putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, packageName)
            }
            startActivity(intent)
        }
    }

    // Queries the unique conversation threads directly from Android's database
    private fun getConversations(): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        val uri: Uri = Uri.parse("content://sms/conversations")
        val projection = arrayOf("thread_id", "msg_count", "snippet")
        
        val cursor: Cursor? = contentResolver.query(uri, projection, null, null, "date DESC")
        
        cursor?.use {
            val threadIdIdx = it.getColumnIndex("thread_id")
            val msgCountIdx = it.getColumnIndex("msg_count")
            val snippetIdx = it.getColumnIndex("snippet")
            
            while (it.moveToNext()) {
                val threadId = it.getString(threadIdIdx) ?: ""
                val msgCount = it.getInt(msgCountIdx)
                val snippet = it.getString(snippetIdx) ?: ""
                
                // Fetch address (phone number) from the canonical addresses or the last message in thread
                val address = getAddressForThread(threadId)

                val conversation = mapOf(
                    "threadId" to threadId,
                    "msgCount" to msgCount,
                    "snippet" to snippet,
                    "address" to address
                )
                list.add(conversation)
            }
        }
        return list
    }

    // Helper to extract the phone number for a specific conversation container
    private fun getAddressForThread(threadId: String): String {
        val uri = Uri.parse("content://sms/inbox")
        val projection = arrayOf("address")
        val selection = "thread_id = ?"
        val selectionArgs = arrayOf(threadId)
        val cursor: Cursor? = contentResolver.query(uri, projection, selection, selectionArgs, "date DESC LIMIT 1")
        
        cursor?.use {
            if (it.moveToFirst()) {
                val idx = it.getColumnIndex("address")
                if (idx >= 0) return it.getString(idx) ?: "Unknown"
            }
        }
        return "Unknown"
    }

    // Queries all individual text messages tied to a specific chat screen
    private fun getMessagesForThread(threadId: String): List<Map<String, Any>> {
        val list = mutableListOf<Map<String, Any>>()
        val uri: Uri = Telephony.Sms.CONTENT_URI
        val projection = arrayOf("_id", "body", "date", "type")
        val selection = "thread_id = ?"
        val selectionArgs = arrayOf(threadId)
        
        val cursor: Cursor? = contentResolver.query(uri, projection, selection, selectionArgs, "date ASC")
        
        cursor?.use {
            val idIdx = it.getColumnIndex("_id")
            val bodyIdx = it.getColumnIndex("body")
            val dateIdx = it.getColumnIndex("date")
            val typeIdx = it.getColumnIndex("type")
            
            while (it.moveToNext()) {
                val body = it.getString(bodyIdx) ?: ""
                val date = it.getLong(dateIdx)
                val type = it.getInt(typeIdx) // 1 = Inbox (Received), 2 = Sent
                
                val message = mapOf(
                    "id" to it.getString(idIdx),
                    "body" to body,
                    "timestamp" to date,
                    "isMe" to (type == Telephony.Sms.MESSAGE_TYPE_SENT)
                )
                list.add(message)
            }
        }
        return list
    }
    
    private fun sendSms(address: String, message: String): Boolean {
        return try {
            // Retrieve instance based on current Android version build constraints
            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                this.getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }

            // Automatically breaks strings longer than 160 GSM characters into clean delivery fragments
            val parts = smsManager.divideMessage(message)
            
            if (parts.size > 1) {
                smsManager.sendMultipartTextMessage(address, null, parts, null, null)
            } else {
                smsManager.sendTextMessage(address, null, message, null, null)
            }
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
