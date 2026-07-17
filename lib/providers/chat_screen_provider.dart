import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sms_channel.dart';
import '../models/sms_message.dart';
import 'app_state.dart'; // Handles communication back up to our Global State

class ChatScreenProvider with ChangeNotifier {
  final SmsChannelService _smsChannel = SmsChannelService();
  final String threadId;
  final String address;
  final AppState
  globalAppState; // Reference handle to manipulate global inbox items instantly

  StreamSubscription<Map<String, dynamic>>? _smsSubscription;

  List<SmsMessage> _messages = [];
  bool _isLoadingMessages = false;
  bool _isSending = false;

  List<SmsMessage> get messages => _messages;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSending => _isSending;

  ChatScreenProvider({
    required this.threadId,
    required this.address,
    required this.globalAppState,
  }) {
    // Automatically query historical content providers the instant the chat screen loads
    fetchMessages();
    _smsSubscription = globalAppState.incomingSmsStream.listen((incomingData) {
      final String incomingAddress = incomingData['address']?.toString() ?? '';
      final String body = incomingData['body']?.toString() ?? '';
      appendIncomingLiveMessageIfMatch(incomingAddress, body);
    });
  }

  /// Screen Specific: Queries all text bubbles belonging to this specific [threadId]
  Future<void> fetchMessages() async {
    _isLoadingMessages = true;
    notifyListeners();

    final List<Map<String, dynamic>> rawMessages = await _smsChannel
        .getMessagesForThread(threadId);
    _messages = rawMessages.map((map) => SmsMessage.fromMap(map)).toList();

    _isLoadingMessages = false;
    notifyListeners();
  }

  /// Screen Specific: Transmits text over cellular bands via native Kotlin methods
  Future<void> sendTextMessage(String textBody) async {
    if (textBody.trim().isEmpty) return;

    _isSending = true;

    // 1. Optimistic UI Update: Create a temporary visual message bubble immediately
    final optimisticMsg = SmsMessage.createOptimistic(body: textBody);
    _messages.add(optimisticMsg);

    // Update global app state index list instantly so the preview text updates under the hood
    globalAppState.updateThreadSnippetWithSentSms(threadId, textBody);
    notifyListeners();

    // 2. Fire the method payload call across the platform channel bridge
    final bool success = await _smsChannel.sendSms(
      address: address,
      message: textBody,
    );

    _isSending = false;

    if (success) {
      // Re-query the system database to overwrite our mock message with real system timestamps
      final List<Map<String, dynamic>> rawMessages = await _smsChannel
          .getMessagesForThread(threadId);
      _messages = rawMessages.map((map) => SmsMessage.fromMap(map)).toList();
    } else {
      // Transmission Failure: Strip the mock optimistic bubble out of the message array
      _messages.removeWhere((m) => m.id == optimisticMsg.id);
    }

    notifyListeners();
  }

  /// Screen Specific: Appends incoming texts live if the sender matches this active thread
  void appendIncomingLiveMessageIfMatch(String incomingAddress, String body) {
    // Clean strings to compare digits safely (ignoring formatting like hyphens or parentheses)
    final cleanCurrent = address.replaceAll(RegExp(r'\D'), '');
    final cleanIncoming = incomingAddress.replaceAll(RegExp(r'\D'), '');

    if (cleanCurrent.isNotEmpty && cleanCurrent == cleanIncoming) {
      _messages.add(
        SmsMessage(
          id: 'live_${DateTime.now().microsecondsSinceEpoch}',
          body: body,
          timestamp: DateTime.now(),
          isMe: false,
        ),
      );
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _smsSubscription?.cancel();
    super.dispose();
  }
}
