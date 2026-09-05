/// A single in-memory chat message used for display and AI context.
class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  /// Compact map sent to the AI API ({role, content} only).
  Map<String, String> toApiMap() => {
        'role': role,
        'content': content,
      };

  /// Full map persisted to Hive (includes timestamp for ordering).
  Map<String, dynamic> toMap() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    DateTime timestamp;
    if (rawTimestamp is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    } else if (rawTimestamp is String) {
      timestamp = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else {
      timestamp = DateTime.now();
    }
    return ChatMessage(
      role: (map['role'] as String?) ?? 'user',
      content: (map['content'] as String?) ?? '',
      timestamp: timestamp,
    );
  }
}
