class ConversationThread {
  final String threadId;
  final int msgCount;
  final String snippet;
  final String address;

  ConversationThread({
    required this.threadId,
    required this.msgCount,
    required this.snippet,
    required this.address,
  });

  /// Factory constructor to instantiate a thread directly from our native Kotlin cursor map
  factory ConversationThread.fromMap(Map<String, dynamic> map) {
    return ConversationThread(
      threadId: map['threadId']?.toString() ?? '',
      msgCount: map['msgCount'] as int? ?? 0,
      snippet: map['snippet']?.toString() ?? '',
      address: map['address']?.toString() ?? 'Unknown',
    );
  }

  /// Helper to return a stylized snippet view if empty
  String get displaySnippet => snippet.trim().isEmpty ? "(No text content)" : snippet;

  /// Returns a clean copy of the thread with a newly updated snippet
  ConversationThread copyWith({String? newSnippet, int? newMsgCount}) {
    return ConversationThread(
      threadId: threadId,
      msgCount: newMsgCount ?? msgCount,
      snippet: newSnippet ?? snippet,
      address: address,
    );
  }
}
