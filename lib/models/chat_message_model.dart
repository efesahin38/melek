class ChatMessageModel {
  final String id;
  final String userId;
  final String message;
  final DateTime createdAt;
  final String? userName; // We'll populate this later or join it from users table

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.message,
    required this.createdAt,
    this.userName,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      message: json['message'] ?? '',
      createdAt: json['created_at'] is DateTime 
          ? json['created_at'] 
          : (DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now()),
      userName: json['users']?['name'], // Supabase join
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };
}
