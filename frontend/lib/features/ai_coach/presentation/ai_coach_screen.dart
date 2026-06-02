import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/di/service_locator.dart';
import '../bloc/ai_coach_bloc.dart';

class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AiCoachBloc>()..add(FetchChatHistory()),
      child: const _AiCoachView(),
    );
  }
}

class _AiCoachView extends StatefulWidget {
  const _AiCoachView();

  @override
  State<_AiCoachView> createState() => _AiCoachViewState();
}

class _AiCoachViewState extends State<_AiCoachView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  final List<String> _suggestions = [
    'Mock interview on Arrays',
    'Explain DP vs Greedy',
    'Recommend Graph problems',
    'How do I prep for Google?',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    context.read<AiCoachBloc>().add(SendMessage(text));
    _textController.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Text('🦉', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Placement Coach', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text('Online Mentor', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
      body: BlocConsumer<AiCoachBloc, AiCoachState>(
        listener: (context, state) {
          if (state.status == AiCoachStatus.loaded || state.status == AiCoachStatus.sending) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          if (state.status == AiCoachStatus.initial || state.status == AiCoachStatus.loading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final messages = state.messages;
          final isSending = state.status == AiCoachStatus.sending;

          return Column(
            children: [
              // Message Panel
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isUser = msg['role'] == 'user';
                    return _buildMessageBubble(msg['content'] ?? '', isUser, isDark);
                  },
                ),
              ),

              // Suggestions Row (only shown when not sending and messages are short)
              if (!isSending && messages.length < 5)
                Container(
                  height: 38,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => _sendMessage(_suggestions[i]),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(AppRadius.round),
                          border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            _suggestions[i],
                            style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87, fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Loading Indicator
              if (isSending)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
                  child: const Row(
                    children: [
                      Text('🦉 thinking', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
                    ],
                  ).animate(onPlay: (controller) => controller.repeat()).shimmer(),
                ),

              // Send message Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        onSubmitted: _sendMessage,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Ask your coach something...',
                          hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(12)),
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(_textController.text),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser, bool isDark) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : (isDark ? AppColors.darkCard : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          border: isUser
              ? null
              : Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }
}
