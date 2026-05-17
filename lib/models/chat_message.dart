class ChatMessage {
  final String id;
  final String role;       // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.user(String content) => ChatMessage(
        id:        DateTime.now().millisecondsSinceEpoch.toString(),
        role:      'user',
        content:   content,
        createdAt: DateTime.now(),
      );

  factory ChatMessage.assistant(String content) => ChatMessage(
        id:        '${DateTime.now().millisecondsSinceEpoch}_a',
        role:      'assistant',
        content:   content,
        createdAt: DateTime.now(),
      );

  // For sending to backend OpenAI messages array
  Map<String, String> toOpenAiMessage() => {'role': role, 'content': content};

  Map<String, dynamic> toJson() => {
        'id':        id,
        'role':      role,
        'content':   content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id:        json['id']        as String,
        role:      json['role']      as String,
        content:   json['content']   as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
