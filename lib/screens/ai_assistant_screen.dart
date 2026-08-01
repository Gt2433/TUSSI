import 'package:flutter/material.dart';
import '../services/ai_assistant_service.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';

/// Full-screen AI Assistant Interface inside Settings
class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  _ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickSuggestions = [
    "📝 كيف أنشئ طلبية جديدة؟",
    "📷 كيف أعمل سكان لكود QR؟",
    "🖼️ كيف أحفظ صورة الفاتورة في المعرض؟",
    "📄 كيف أصدر فاتورة PDF بالفرنسية؟",
    "💳 كيف أتابع وأعدل الذمم؟",
  ];

  @override
  void initState() {
    super.initState();
    // Initial welcome message (Clean text without RTL-breaking markdown asterisks)
    _messages.add(
      _ChatMessage(
        text: "أهلاً بك في مساعد TUSSI الذكي!\n\n"
            "أنا حافظ التطبيق عن ظهر قلب ومجيبك الخاص عن أي استفسار يتعلق بشرائح، طلبيات، فواتير، وخدمات تطبيق TUSSI. اسألني وسأشرح لك بالتفصيل! ✨",
        isUser: false,
      ),
    );
  }

  void _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _inputController.clear();

    setState(() {
      _messages.add(_ChatMessage(text: trimmed, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    final response = await AiAssistantService.askAssistant(trimmed);

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.tr('tab_orders') == 'الطلبيات';

    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.accentAmber,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isAr ? 'مساعد TUSSI الذكي' : 'TUSSI AI Assistant',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick suggestion chips
          Container(
            height: 48,
            color: AppTheme.surfaceCard.withValues(alpha: 0.5),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _quickSuggestions.length,
              itemBuilder: (ctx, idx) {
                final suggestion = _quickSuggestions[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: AppTheme.surfaceCard,
                    side: BorderSide(color: AppTheme.accentAmber.withValues(alpha: 0.3)),
                    label: Text(
                      suggestion,
                      style: TextStyle(fontSize: 11, color: AppTheme.accentAmber),
                    ),
                    onPressed: () => _sendMessage(suggestion),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: Colors.white12),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, idx) {
                final msg = _messages[idx];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Loading typing indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isAr ? 'مساعد TUSSI يفكر ويجهز الإجابة...' : 'TUSSI AI is thinking...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.accentAmber.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Input field bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              border: const Border(top: BorderSide(color: Colors.white12)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: isAr ? 'اسأل عن أي خاصية في تطبيق TUSSI...' : 'Ask any question about TUSSI...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: AppTheme.surfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _sendMessage(_inputController.text),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
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

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppTheme.accentAmber.withValues(alpha: 0.18)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: Border.all(
            color: msg.isUser
                ? AppTheme.accentAmber.withValues(alpha: 0.4)
                : Colors.white12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  msg.isUser ? Icons.person_rounded : Icons.auto_awesome_rounded,
                  size: 13,
                  color: msg.isUser ? AppTheme.accentAmber : Colors.white60,
                ),
                const SizedBox(width: 4),
                Text(
                  msg.isUser ? 'أنت' : 'مساعد TUSSI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: msg.isUser ? AppTheme.accentAmber : Colors.white60,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              msg.text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
