import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../models/user_model.dart';
import '../../models/chat_message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  Map<String, UserModel> _usersMap = {};
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await SupabaseService.getAllUsers();
      if (mounted) {
        setState(() {
          _usersMap = {for (var u in users) u.id: u};
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    _messageController.clear();

    try {
      await SupabaseService.sendChatMessage(
        userId: user.id,
        message: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Senden fehlgeschlagen: $e',
                style: const TextStyle(color: AppTheme.textPrimary)),
            backgroundColor: AppTheme.errorBg,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.borderGold, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.forum_rounded,
                  color: AppTheme.goldPrimary,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Team Chat',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Gemeinsamer Austausch',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Messages ──────────────────────────────────────────────
          Expanded(
            child: _isLoadingUsers
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.goldPrimary,
                    ),
                  )
                : StreamBuilder<List<dynamic>>(
                    stream: SupabaseService.getChatStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Fehler beim Laden des Chats:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.error),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.goldPrimary,
                          ),
                        );
                      }

                      final messages = snapshot.data!
                          .map((data) => ChatMessageModel.fromJson(data))
                          .toList();

                      // Autoscroll to bottom logic could be added here
                      // For now, we reverse the list view
                      final reversedMessages = messages.reversed.toList();

                      if (reversedMessages.isEmpty) {
                        return const Center(
                          child: Text(
                            'Noch keine Nachrichten.\nSchreibe die erste!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Start from bottom
                        padding: const EdgeInsets.all(16),
                        itemCount: reversedMessages.length,
                        itemBuilder: (context, index) {
                          final msg = reversedMessages[index];
                          final isMe = msg.userId == currentUser?.id;
                          final sender = _usersMap[msg.userId];
                          final senderName = sender?.name ?? 'Unbekannt';

                          // Format time
                          final timeStr =
                              DateFormat('HH:mm').format(msg.createdAt.toLocal());
                          final dateStr =
                              DateFormat('dd.MM.yy').format(msg.createdAt.toLocal());

                          return _ChatBubble(
                            message: msg.message,
                            senderName: senderName,
                            timeStr: '$dateStr $timeStr',
                            isMe: isMe,
                            isAdmin: sender?.isAdmin ?? false,
                          );
                        },
                      );
                    },
                  ),
          ),

          // ── Input Area ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              border: const Border(
                top: BorderSide(color: AppTheme.borderGold, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Nachricht schreiben...',
                          hintStyle: TextStyle(color: AppTheme.textMuted),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.goldShadow,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppTheme.bgDark),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final String senderName;
  final String timeStr;
  final bool isMe;
  final bool isAdmin;

  const _ChatBubble({
    required this.message,
    required this.senderName,
    required this.timeStr,
    required this.isMe,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Name row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isMe && isAdmin) ...[
                  const Icon(Icons.admin_panel_settings_rounded,
                      color: AppTheme.goldPrimary, size: 14),
                  const SizedBox(width: 4),
                ],
                Text(
                  isMe ? 'Ich' : senderName,
                  style: TextStyle(
                    color: isMe
                        ? AppTheme.goldPrimary
                        : (isAdmin ? AppTheme.textGold : AppTheme.textSecondary),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Bubble
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.goldGlow : AppTheme.bgCardElevated,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(20),
              ),
              border: Border.all(
                color: isMe ? AppTheme.goldPrimary : AppTheme.border,
                width: 1,
              ),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? AppTheme.textGold : AppTheme.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
