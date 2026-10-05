import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

enum ChatMode { general, mental, diet, fitness }

class ChatScreen extends ConsumerStatefulWidget {
  final ChatMode mode;
  const ChatScreen({super.key, this.mode = ChatMode.general});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _api = ApiService();
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _addWelcome();
  }

  void _addWelcome() {
    final greetings = {
      ChatMode.mental:
          "Hello! I'm your Mental Wellness companion. How are you feeling today? I'm here to listen and support you. 💙",
      ChatMode.diet:
          "Hi! I'm your Diet & Nutrition advisor. Tell me about your dietary goals or any questions about nutrition! 🥗",
      ChatMode.fitness:
          "Hey there! I'm your Fitness coach. Ready to help you reach your health and fitness goals! 💪",
      ChatMode.general:
          "Hello! I'm CREVA Assistant, your AI health companion. How can I help you today? 🏥",
    };
    _messages.add(_ChatMessage(
      text: greetings[widget.mode]!,
      isUser: false,
      time: _timeNow(),
    ));
  }

  String _timeNow() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: true,
        time: _timeNow(),
      ));
      _loading = true;
    });
    _ctrl.clear();
    _scrollToBottom();

    try {
      final contextPrefix = {
        ChatMode.mental: '[Mental Health Context] ',
        ChatMode.diet: '[Diet & Nutrition Context] ',
        ChatMode.fitness: '[Fitness & Exercise Context] ',
        ChatMode.general: '',
      }[widget.mode]!;

      final response = await _api.chat('$contextPrefix$text');
      setState(() {
        _messages.add(_ChatMessage(
          text: response['response'] ??
              response['message'] ??
              'I understand. Let me help you with that.',
          isUser: false,
          time: _timeNow(),
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text:
              "I'm having trouble connecting right now. Please try again in a moment.",
          isUser: false,
          time: _timeNow(),
          isError: true,
        ));
      });
    }

    setState(() => _loading = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.mode) {
      case ChatMode.mental:
        return 'Mental Wellness';
      case ChatMode.diet:
        return 'Diet & Nutrition';
      case ChatMode.fitness:
        return 'Fitness Coach';
      case ChatMode.general:
        return 'CREVA Assistant';
    }
  }

  Color get _modeColor {
    switch (widget.mode) {
      case ChatMode.mental:
        return const Color(0xFF10B981);
      case ChatMode.diet:
        return const Color(0xFFF59E0B);
      case ChatMode.fitness:
        return const Color(0xFFEF4444);
      case ChatMode.general:
        return CrevaColors.primary;
    }
  }

  IconData get _modeIcon {
    switch (widget.mode) {
      case ChatMode.mental:
        return Icons.self_improvement;
      case ChatMode.diet:
        return Icons.restaurant_menu;
      case ChatMode.fitness:
        return Icons.fitness_center;
      case ChatMode.general:
        return Icons.smart_toy_outlined;
    }
  }

  List<String> get _suggestions {
    switch (widget.mode) {
      case ChatMode.mental:
        return [
          'I feel anxious',
          'Help me relax',
          'Breathing exercise',
          'I feel stressed',
        ];
      case ChatMode.diet:
        return [
          'Meal plan for today',
          'Healthy breakfast ideas',
          'Calorie advice',
          'Low sugar foods',
        ];
      case ChatMode.fitness:
        return [
          '10 min workout',
          'Beginner routine',
          'Stretch exercises',
          'Cardio tips',
        ];
      case ChatMode.general:
        return [
          'Check my vitals',
          'Medication reminder',
          'Health tips',
          'Book appointment',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrevaColors.background,
      appBar: AppBar(
        backgroundColor: CrevaColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: CrevaColors.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _modeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(_modeIcon, color: _modeColor, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CrevaColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: CrevaColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ONLINE',
                      style: TextStyle(
                        fontSize: 10,
                        color: CrevaColors.success,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search,
                color: CrevaColors.textPrimary, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert,
                color: CrevaColors.textPrimary, size: 22),
            onPressed: () => _showOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                    child: Divider(color: CrevaColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 10,
                      color: CrevaColors.textTertiary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                    child: Divider(color: CrevaColors.border)),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _TypingIndicator(color: _modeColor);
                }
                return _MessageBubble(
                  message: _messages[index],
                  modeColor: _modeColor,
                  modeIcon: _modeIcon,
                );
              },
            ),
          ),

          // Suggestions shown only at start
          if (_messages.length <= 1)
            _SuggestionChips(
              suggestions: _suggestions,
              color: _modeColor,
              onTap: (s) {
                _ctrl.text = s;
                _send();
              },
            ),

          // Input bar
          _InputBar(
            controller: _ctrl,
            onSend: _send,
            modeColor: _modeColor,
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CrevaColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CrevaColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _OptionTile(
              icon: Icons.delete_outline,
              label: 'Clear conversation',
              color: CrevaColors.error,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _messages.clear();
                  _addWelcome();
                });
              },
            ),
            _OptionTile(
              icon: Icons.share_outlined,
              label: 'Share conversation',
              color: CrevaColors.textPrimary,
              onTap: () => Navigator.pop(context),
            ),
            _OptionTile(
              icon: Icons.info_outline,
              label: 'About this assistant',
              color: CrevaColors.textPrimary,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Chat Message Model ────────────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  final bool isError;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.isError = false,
  });
}

// ── Message Bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final Color modeColor;
  final IconData modeIcon;

  const _MessageBubble({
    required this.message,
    required this.modeColor,
    required this.modeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI avatar
          if (!isUser) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: modeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(modeIcon, color: modeColor, size: 18),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? modeColor
                        : message.isError
                            ? CrevaColors.error
                                .withValues(alpha: 0.08)
                            : CrevaColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft:
                          Radius.circular(isUser ? 18 : 4),
                      bottomRight:
                          Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : message.isError
                              ? CrevaColors.error
                              : CrevaColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: CrevaColors.textTertiary,
                      ),
                    ),
                    if (isUser) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all,
                        size: 12,
                        color: CrevaColors.success,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.smart_toy_outlined, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CrevaColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AnimatedDot(delay: 0, color: color),
                const SizedBox(width: 5),
                _AnimatedDot(delay: 200, color: color),
                const SizedBox(width: 5),
                _AnimatedDot(delay: 400, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final int delay;
  final Color color;
  const _AnimatedDot({required this.delay, required this.color});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ── Suggestion Chips ──────────────────────────────────────────────────────────
class _SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final Color color;
  final ValueChanged<String> onTap;

  const _SuggestionChips({
    required this.suggestions,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: CrevaColors.surface,
        border: Border(top: BorderSide(color: CrevaColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick suggestions',
            style: TextStyle(
              fontSize: 11,
              color: CrevaColors.textTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return GestureDetector(
                onTap: () => onTap(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Input Bar ─────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Color modeColor;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.modeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: CrevaColors.surface,
        border: Border(top: BorderSide(color: CrevaColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: CrevaColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: CrevaColors.border),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.attach_file,
                  size: 18, color: CrevaColors.textTertiary),
              onPressed: () {},
            ),
          ),

          // Text field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: CrevaColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: CrevaColors.border),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                      color: CrevaColors.textTertiary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: modeColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: modeColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Option Tile (bottom sheet) ────────────────────────────────────────────────
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: color, size: 18),
      onTap: onTap,
    );
  }
}