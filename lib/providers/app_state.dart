import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sms_channel.dart';
import '../models/conversation_thread.dart';

class AppState with ChangeNotifier {
  final SmsChannelService _smsChannel = SmsChannelService();
  final StreamController<Map<String, dynamic>> _incomingSmsController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get incomingSmsStream =>
      _incomingSmsController.stream;

  List<ConversationThread> _threads = [];
  bool _isFetchingThreads = false;

  List<ConversationThread> get threads => _threads;
  bool get isFetchingThreads => _isFetchingThreads;

  /// Fetches all threads directly from the Android system SMS provider database
  Future<void> fetchConversations() async {
    _isFetchingThreads = true;
    notifyListeners();

    final List<Map<String, dynamic>> rawConversations = await _smsChannel
        .getConversations();
    _threads = rawConversations
        .map((map) => ConversationThread.fromMap(map))
        .toList();

    _isFetchingThreads = false;
    notifyListeners();
  }

  /// Handles incoming live SMS to update the global chat list in real-time
  void handleIncomingLiveSms(Map<String, dynamic> incomingData) {
    final String address = incomingData['address']?.toString() ?? 'Unknown';
    final String body = incomingData['body']?.toString() ?? '';

    final int existingIndex = _threads.indexWhere((t) => t.address == address);

    if (existingIndex != -1) {
      final currentThread = _threads[existingIndex];
      _threads.removeAt(existingIndex);
      _threads.insert(
        0,
        currentThread.copyWith(
          newSnippet: body,
          newMsgCount: currentThread.msgCount + 1,
        ),
      );
    } else {
      fetchConversations();
      _incomingSmsController.add(incomingData);
      return;
    }
    notifyListeners();
    _incomingSmsController.add(incomingData);
  }

  /// Optimistically updates a thread's preview snippet text when a user sends a text message
  void updateThreadSnippetWithSentSms(String threadId, String body) {
    final int index = _threads.indexWhere((t) => t.threadId == threadId);
    if (index != -1) {
      final currentThread = _threads[index];
      _threads.removeAt(index);
      _threads.insert(0, currentThread.copyWith(newSnippet: body));
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _incomingSmsController.close();
    super.dispose();
  }
}
