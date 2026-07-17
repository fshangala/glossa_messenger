class SmsMessage {
  final String id;
  final String body;
  final DateTime timestamp;
  final bool isMe;

  SmsMessage({
    required this.id,
    required this.body,
    required this.timestamp,
    required this.isMe,
  });

  /// Factory constructor to instantiate an individual text message bubble from Kotlin
  factory SmsMessage.fromMap(Map<String, dynamic> map) {
    final rawTimestamp =
        map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

    return SmsMessage(
      id: map['id']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(rawTimestamp),
      isMe: map['isMe'] as bool? ?? false,
    );
  }

  /// Factory constructor to create a local optimistic message state instantly when sending
  factory SmsMessage.createOptimistic({required String body}) {
    return SmsMessage(
      id: 'optimistic_${DateTime.now().microsecondsSinceEpoch}',
      body: body,
      timestamp: DateTime.now(),
      isMe: true,
    );
  }
}
