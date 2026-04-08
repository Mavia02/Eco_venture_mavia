class ChatMessage {
  final String sender; // 'user' or 'bot'
  final String message;
  final DateTime time;
  final String userId;
  final bool isUser;

  ChatMessage({
    required this.sender,
    required this.isUser,
    required this.userId,
    required this.message,
    required this.time,
  });

  // Converts a ChatMessage into a Map for Sqflite
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sender': sender,
      'isUser': isUser ? 1 : 0, // SQLite doesn't store bools, we use 0/1
      'message': message,
      'time': time.toIso8601String(),
    };
  }

  // Essential for ChatDatabase: Converts SQL rows back into ChatMessage objects
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      userId: map['userId'] ?? '',
      sender: map['sender'] ?? 'bot',
      isUser: map['isUser'] == 1,
      message: map['message'] ?? '',
      time: DateTime.parse(map['time'] ?? DateTime.now().toIso8601String()),
    );
  }
}
