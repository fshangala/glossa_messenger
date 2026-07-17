import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SmsChannelService {
  // Define the exact channel string matched in MainActivity.kt
  static const MethodChannel _channel = MethodChannel('com.fshangala.apps.glossa_messenger/sms');

  /// Checks if Glossa Messenger is currently the default SMS app on the device.
  Future<bool> isDefaultSmsApp() async {
    try {
      final bool isDefault = await _channel.invokeMethod('isDefaultSmsApp');
      return isDefault;
    } on PlatformException catch (e) {
      debugPrint('Error checking default SMS app status: ${e.message}');
      return false;
    }
  }

  /// Prompts the Android OS system dialog to set Glossa Messenger as the default app.
  Future<bool> requestDefaultSmsApp() async {
    try {
      final bool success = await _channel.invokeMethod('requestDefaultSmsApp');
      return success;
    } on PlatformException catch (e) {
      debugPrint('Error requesting default SMS app status: ${e.message}');
      return false;
    }
  }

  /// Queries all conversation threads directly from the native Android content provider cursor.
  /// Returns a raw list of maps containing threadId, msgCount, snippet, and address.
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getConversations');
      if (result == null) return [];
      
      return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } on PlatformException catch (e) {
      debugPrint('Error fetching conversation threads: ${e.message}');
      return [];
    }
  }

  /// Queries all individual messages tied to a specific [threadId].
  /// Returns a raw list of maps containing id, body, timestamp, and isMe.
  Future<List<Map<String, dynamic>>> getMessagesForThread(String threadId) async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod(
        'getMessagesForThread',
        {'threadId': threadId},
      );
      if (result == null) return [];

      return result.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } on PlatformException catch (e) {
      debugPrint('Error fetching messages for thread $threadId: ${e.message}');
      return [];
    }
  }

  /// Dispatches a text payload over the carrier network using the native SmsManager.
  /// Returns true if successfully passed to the cellular tower dispatch queue.
  Future<bool> sendSms({required String address, required String message}) async {
    try {
      final bool success = await _channel.invokeMethod('sendSms', {
        'address': address,
        'message': message,
      });
      return success;
    } on PlatformException catch (e) {
      debugPrint('Error dispatching outbound SMS: ${e.message}');
      return false;
    }
  }
}
