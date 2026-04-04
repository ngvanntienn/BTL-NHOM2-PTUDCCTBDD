import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add({
      'role': 'bot',
      'text': 'Xin chào! 👋 Tôi là trợ lý AI của FoodExpress.\n\nHôm nay bạn muốn ăn gì? Tôi có thể gợi ý món ăn, quán ăn, hoặc giúp bạn tìm combo tiết kiệm nhất nhé!',
      'time': _now(),
    });
  }

  String _now() {
    final now = TimeOfDay.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': text.trim(), 'time': _now()});
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate AI typing reply
    Future.delayed(const Duration(seconds: 1, milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'bot',
          'text': _getAIReply(text),
          'time': _now(),
          'hasCard': text.toLowerCase().contains('gợi ý') || text.toLowerCase().contains('ăn gì') || text.toLowerCase().contains('đề xuất'),
        });
      });
      _scrollToBottom();
    });
  }

  String _getAIReply(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('ăn gì') || lower.contains('gợi ý') || lower.contains('đề xuất')) {
      return 'Để tôi gợi ý cho bạn một số món hấp dẫn hôm nay nhé! 🍜';
    } else if (lower.contains('ship') || lower.contains('giao hàng')) {
      return 'Phí giao hàng dao động từ 10.000đ - 25.000đ tuỳ khoảng cách. Đơn trên 150.000đ sẽ được miễn phí ship! 🛵';
    } else if (lower.contains('voucher') || lower.contains('mã giảm')) {
      return 'Bạn có thể xem danh sách mã giảm giá trong Hồ sơ > Ví & Khuyến mãi. Hoặc nhập mã khi thanh toán nhé! 🎫';
    }
    return 'Tôi hiểu rồi!\n\nBạn có thể hỏi tôi về: gợi ý món ăn, phí giao hàng, voucher, hoặc bất kỳ điều gì liên quan đến FoodExpress nhé! 😊';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined, color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Trợ lý AI', style: TextStyle(color: Color(0xFF1C1C1E), fontWeight: FontWeight.bold, fontSize: 16)),
                Text('FoodExpress', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
              ],
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                final isBot = msg['role'] == 'bot';
                return Column(
                  children: [
                    isBot
                        ? _buildBotBubble(msg['text'], msg['time'])
                        : _buildUserBubble(msg['text'], msg['time']),
                    if (isBot && msg['hasCard'] == true) ...[
                      const SizedBox(height: 8),
                      _buildFoodSuggestionCard(),
                    ]
                  ],
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBotBubble(String text, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF1C1C1E))),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserBubble(String text, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(text, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.white)),
              const SizedBox(height: 4),
              Text(time, style: const TextStyle(fontSize: 11, color: Colors.white60)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(100),
            const SizedBox(width: 4),
            _dot(200),
            const SizedBox(width: 4),
            _dot(300),
          ],
        ),
      ),
    );
  }

  Widget _dot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeInOut,
      builder: (context, value, child) => Opacity(
        opacity: 0.4 + value * 0.6,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildFoodSuggestionCard() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 100,
                color: const Color(0xFFF0F0F0),
                child: const Center(
                  child: Icon(Icons.ramen_dining, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gợi ý của AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Text('Món ăn sẽ được hiển thị ở đây', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text('Thêm vào giỏ'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
