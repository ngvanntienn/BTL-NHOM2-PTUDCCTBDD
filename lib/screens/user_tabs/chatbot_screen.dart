import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_routes.dart';
import '../../services/n8n_chatbot_service.dart';
import '../../theme/app_theme.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
  final N8nChatbotService _n8nService = N8nChatbotService();
  bool _isTyping = false;
  bool _isLoadingHistory = true;

  CollectionReference<Map<String, dynamic>>? get _chatCollection {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('chat_history')
        .doc(uid)
        .collection('messages');
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final TimeOfDay t = TimeOfDay.fromDateTime(time);
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime time) {
    final String d =
        '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
    return '$d ${_formatTime(time)}';
  }

  String _formatPrice(double price) {
    if (price <= 0) {
      return 'Giá đang cập nhật';
    }
    return '${price.toStringAsFixed(0)}d';
  }

  String _repairText(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) {
      return input;
    }

    String decodeMixedLatin1Utf8(String source) {
      final StringBuffer out = StringBuffer();
      final List<int> chunk = <int>[];

      void flush() {
        if (chunk.isEmpty) {
          return;
        }
        try {
          out.write(utf8.decode(chunk));
        } catch (_) {
          out.write(String.fromCharCodes(chunk));
        }
        chunk.clear();
      }

      for (final int codeUnit in source.codeUnits) {
        if (codeUnit <= 255) {
          chunk.add(codeUnit);
        } else {
          flush();
          out.writeCharCode(codeUnit);
        }
      }
      flush();

      return out.toString();
    }

    // Run two passes to fix both single and nested mojibake cases.
    final String pass1 = decodeMixedLatin1Utf8(input);
    final String pass2 = decodeMixedLatin1Utf8(pass1);
    return pass2;
  }

  List<Map<String, dynamic>> _normalizeSuggestions(dynamic raw) {
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    for (final dynamic element in raw) {
      if (element is! Map) {
        continue;
      }

      final String foodId =
          (element['foodId'] ?? element['id'] ?? element['food_id'] ?? '')
              .toString();
      final String name = (element['name'] ?? 'Mon goi y').toString();
      final String category = (element['category'] ?? '').toString();
      final String reason = (element['reason'] ?? '').toString();
      final double price = element['price'] is num
          ? (element['price'] as num).toDouble()
          : 0;
      final double rating = element['rating'] is num
          ? (element['rating'] as num).toDouble()
          : 0;

      items.add(<String, dynamic>{
        'foodId': foodId,
        'name': name,
        'category': category,
        'reason': reason,
        'price': price,
        'rating': rating,
      });
    }

    return items;
  }

  List<Map<String, dynamic>> _historyForN8n() {
    final Iterable<Map<String, dynamic>> recent = _messages.reversed
        .take(12)
        .toList()
        .reversed;
    return recent
        .map(
          (Map<String, dynamic> msg) => <String, dynamic>{
            'role': (msg['role'] ?? 'user').toString(),
            'text': (msg['text'] ?? '').toString(),
          },
        )
        .where(
          (Map<String, dynamic> item) =>
              (item['text'] as String).trim().isNotEmpty,
        )
        .toList();
  }

  Map<String, dynamic> _greetingMessage() {
    return <String, dynamic>{
      'role': 'bot',
      'text':
          'Xin chào! Tôi là AI Chef của FoodExpress.\n\nHôm nay bạn đang thèm gì nào? Tôi sẵn sàng gợi ý món ngon cho bạn!',
      'time': _formatTime(DateTime.now()),
      'hasCard': false,
      'foodSuggestions': <Map<String, dynamic>>[],
    };
  }

  Future<void> _loadHistory() async {
    final CollectionReference<Map<String, dynamic>>? chatRef = _chatCollection;
    if (chatRef == null) {
      setState(() {
        _messages
          ..clear()
          ..add(_greetingMessage());
        _isLoadingHistory = false;
      });
      return;
    }

    final QuerySnapshot<Map<String, dynamic>> snap = await chatRef
        .orderBy('createdAt')
        .get();

    if (snap.docs.isEmpty) {
      final Map<String, dynamic> greet = _greetingMessage();
      await _persistMessage(
        role: 'bot',
        text: greet['text'] as String,
        hasCard: false,
      );
      setState(() {
        _messages
          ..clear()
          ..add(greet);
        _isLoadingHistory = false;
      });
      _scrollToBottom();
      return;
    }

    final List<Map<String, dynamic>> mapped = snap.docs.map((doc) {
      final Map<String, dynamic> data = doc.data();
      final DateTime createdAt =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final List<Map<String, dynamic>> suggestions = _normalizeSuggestions(
        data['foodSuggestions'],
      );
      return <String, dynamic>{
        'role': (data['role'] ?? 'bot').toString(),
        'text': _repairText((data['text'] ?? '').toString()),
        'time': _formatTime(createdAt),
        'hasCard': data['hasCard'] == true || suggestions.isNotEmpty,
        'foodSuggestions': suggestions,
      };
    }).toList();

    setState(() {
      _messages
        ..clear()
        ..addAll(mapped);
      _isLoadingHistory = false;
    });
    _scrollToBottom();
  }

  Future<void> _persistMessage({
    required String role,
    required String text,
    bool hasCard = false,
    List<Map<String, dynamic>> foodSuggestions = const <Map<String, dynamic>>[],
  }) async {
    final CollectionReference<Map<String, dynamic>>? chatRef = _chatCollection;
    if (chatRef == null) return;

    final Map<String, dynamic> payload = <String, dynamic>{
      'role': role,
      'text': text,
      'hasCard': hasCard,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (foodSuggestions.isNotEmpty) {
      payload['foodSuggestions'] = foodSuggestions;
    }

    await chatRef.add(payload);
  }

  Future<void> _appendMessage({
    required String role,
    required String text,
    bool hasCard = false,
    List<Map<String, dynamic>> foodSuggestions = const <Map<String, dynamic>>[],
  }) async {
    final String fixedText = _repairText(text);
    setState(() {
      _messages.add(<String, dynamic>{
        'role': role,
        'text': fixedText,
        'time': _formatTime(DateTime.now()),
        'hasCard': hasCard,
        'foodSuggestions': foodSuggestions,
      });
    });
    _scrollToBottom();
    await _persistMessage(
      role: role,
      text: fixedText,
      hasCard: hasCard,
      foodSuggestions: foodSuggestions,
    );
  }

  Future<void> _clearHistory() async {
    final CollectionReference<Map<String, dynamic>>? chatRef = _chatCollection;
    if (chatRef != null) {
      final QuerySnapshot<Map<String, dynamic>> docs = await chatRef.get();
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    setState(() {
      _messages
        ..clear()
        ..add(_greetingMessage());
    });

    _showSnack('Đã xóa lịch sử chat.');
    _scrollToBottom();
  }

  Future<void> _openHistorySheet() async {
    final CollectionReference<Map<String, dynamic>>? chatRef = _chatCollection;
    if (chatRef == null) {
      _showSnack('Bạn cần đăng nhập để xem lịch sử chat.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: chatRef.orderBy('createdAt', descending: true).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                );
              }

              final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                  snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              if (docs.isEmpty) {
                return const Center(
                  child: Text(
                    'Chưa có lịch sử chat.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
                    child: Row(
                      children: [
                        Text(
                          'Lịch sử chat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.dividerColor),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final Map<String, dynamic> data = docs[index].data();
                        final String role = (data['role'] ?? 'bot').toString();
                        final String text = _repairText(
                          (data['text'] ?? '').toString(),
                        );
                        final DateTime createdAt =
                            (data['createdAt'] as Timestamp?)?.toDate() ??
                            DateTime.now();

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: role == 'bot'
                                  ? AppTheme.primaryColor.withOpacity(0.12)
                                  : AppTheme.textSecondary.withOpacity(0.16),
                              child: Icon(
                                role == 'bot'
                                    ? Icons.smart_toy_outlined
                                    : Icons.person_outline,
                                size: 16,
                                color: role == 'bot'
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            title: Text(
                              text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                height: 1.35,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _formatDateTime(createdAt),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _fallbackReply(String input) {
    final String l = input.toLowerCase();
    if (l.contains('ăn gì') || l.contains('gợi ý') || l.contains('đề xuất')) {
      return 'Tuyệt vời! Tôi đã nhận yêu cầu gợi ý món cho bạn. Bạn mô tả thêm ngân sách hoặc số người ăn nhé.';
    }
    if (l.contains('ship') || l.contains('giao hàng')) {
      return 'Phí giao hàng thường từ 10.000đ đến 25.000đ. Đơn trên 150.000đ có thể được freeship tùy khu vực.';
    }
    if (l.contains('voucher') || l.contains('mã giảm')) {
      return 'Bạn vào Hồ sơ > Ví và Khuyến mãi để xem mã giảm giá hiện có.';
    }
    return 'Tôi đang xử lý theo kiểu dự phòng. Bạn thử hỏi: gợi ý combo cho 2 người, tìm món cay, hoặc món đang trend.';
  }

  String _normalizeForMatch(String input) {
    String s = input.toLowerCase();
    const Map<String, String> accents = <String, String>{
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };

    accents.forEach((String from, String to) {
      s = s.replaceAll(from, to);
    });
    return s;
  }

  int? _extractPeopleCount(String prompt) {
    final RegExp rx = RegExp(r'(\d+)\s*(nguoi|nguoi an|suat|phan)');
    final Match? m = rx.firstMatch(_normalizeForMatch(prompt));
    if (m == null) {
      return null;
    }
    return int.tryParse(m.group(1) ?? '');
  }

  double? _extractBudgetVnd(String prompt) {
    final String p = _normalizeForMatch(prompt);
    final RegExp rx = RegExp(r'(\d+(?:[\.,]\d+)?)\s*(k|nghin|ngan|tr|trieu)?');
    final Iterable<Match> matches = rx.allMatches(p);

    double? best;
    for (final Match m in matches) {
      final String raw = (m.group(1) ?? '').replaceAll(',', '.');
      final double? number = double.tryParse(raw);
      if (number == null || number <= 0) {
        continue;
      }
      final String unit = (m.group(2) ?? '').toLowerCase();
      final double value = switch (unit) {
        'k' || 'nghin' || 'ngan' => number * 1000,
        'tr' || 'trieu' => number * 1000000,
        _ => number,
      };
      if (best == null || value > best) {
        best = value;
      }
    }

    return best;
  }

  bool _containsAny(String haystack, List<String> needles) {
    for (final String keyword in needles) {
      if (haystack.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  Set<String> _extractPromptKeywords(String prompt) {
    final String normalized = _normalizeForMatch(prompt);
    final Set<String> stopwords = <String>{
      'tim',
      'mon',
      'goi',
      'y',
      'goi',
      'combo',
      'cho',
      'nguoi',
      'an',
      'buoi',
      'toi',
      'trua',
      'sang',
      'de',
      'it',
      'khong',
      'cay',
      'budget',
      'duoi',
      'tren',
      'va',
      'hoac',
      'la',
      'nhung',
      'nhe',
      'voi',
      'toi',
      'toi',
      'nhieu',
      're',
      'ngon',
      'hom',
      'nay',
      'dang',
      'the',
      'nao',
    };

    final Iterable<String> tokens = normalized
        .split(RegExp(r'[^a-z0-9]+'))
        .where((String t) => t.length >= 3 && !stopwords.contains(t));
    return tokens.toSet();
  }

  List<Map<String, dynamic>> _filterSuggestionsByPrompt({
    required String prompt,
    required List<Map<String, dynamic>> suggestions,
  }) {
    if (suggestions.isEmpty) {
      return suggestions;
    }

    final String normalizedPrompt = _normalizeForMatch(prompt);
    final int? people = _extractPeopleCount(prompt);
    final double? budget = _extractBudgetVnd(prompt);
    final bool wantsSpicy =
        normalizedPrompt.contains('cay') &&
        !_containsAny(normalizedPrompt, <String>['it cay', 'khong cay']);
    final bool wantsNotSpicy = _containsAny(normalizedPrompt, <String>[
      'it cay',
      'khong cay',
    ]);
    final bool hasPriceLimitHint = _containsAny(normalizedPrompt, <String>[
      're',
      'gia mem',
      'gia tot',
      'tiet kiem',
      'duoi',
    ]);
    final Set<String> promptKeywords = _extractPromptKeywords(prompt);

    final double? perPersonBudget =
        (budget != null && people != null && people > 0)
        ? budget / people
        : null;

    final bool hasHardConstraints =
        budget != null ||
        people != null ||
        wantsSpicy ||
        wantsNotSpicy ||
        hasPriceLimitHint ||
        promptKeywords.isNotEmpty;

    final List<String> spicyKeywords = <String>[
      'cay',
      'spicy',
      'xot thai',
      'kimchi',
      'sa te',
      'sate',
      'la lot',
      'thai lan',
    ];

    final List<Map<String, dynamic>> filtered = suggestions.where((s) {
      final double price = (s['price'] as num?)?.toDouble() ?? 0;
      final String merged = _normalizeForMatch(
        '${s['name'] ?? ''} ${s['category'] ?? ''} ${s['reason'] ?? ''}',
      );

      if (budget != null && price > 0) {
        final double hardLimit = perPersonBudget != null
            ? perPersonBudget * 1.2
            : budget;
        if (price > hardLimit) {
          return false;
        }
      }

      if (wantsSpicy && !_containsAny(merged, spicyKeywords)) {
        return false;
      }

      if (wantsNotSpicy && _containsAny(merged, spicyKeywords)) {
        return false;
      }

      if (promptKeywords.isNotEmpty) {
        bool keywordMatched = false;
        for (final String k in promptKeywords) {
          if (merged.contains(k)) {
            keywordMatched = true;
            break;
          }
        }
        if (!keywordMatched && promptKeywords.length <= 3) {
          return false;
        }
      }

      return true;
    }).toList();

    if (filtered.isEmpty && hasHardConstraints) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> base = filtered.isEmpty
        ? suggestions
        : filtered;
    base.sort((Map<String, dynamic> a, Map<String, dynamic> b) {
      final double ar = (a['rating'] as num?)?.toDouble() ?? 0;
      final double br = (b['rating'] as num?)?.toDouble() ?? 0;
      if (ar != br) {
        return br.compareTo(ar);
      }
      final double ap = (a['price'] as num?)?.toDouble() ?? 0;
      final double bp = (b['price'] as num?)?.toDouble() ?? 0;
      return ap.compareTo(bp);
    });

    return base.take(3).toList();
  }

  Map<String, dynamic> _mapFoodToSuggestion(Map<String, dynamic> data) {
    final String foodId = (data['foodId'] ?? data['id'] ?? '').toString();
    final String name = (data['name'] ?? 'Món').toString();
    final String category = (data['category'] ?? '').toString();
    final String reason = (data['description'] ?? '').toString();
    final double price = (data['price'] is num)
        ? (data['price'] as num).toDouble()
        : 0;
    final double rating = (data['rating'] is num)
        ? (data['rating'] as num).toDouble()
        : 0;

    return <String, dynamic>{
      'foodId': foodId,
      'name': name,
      'category': category,
      'reason': reason,
      'price': price,
      'rating': rating,
    };
  }

  Future<Map<String, dynamic>> _smartFallbackReply(String input) async {
    final String l = input.toLowerCase();

    if (l.contains('voucher') ||
        l.contains('mã giảm') ||
        l.contains('khuyến mãi')) {
      final QuerySnapshot<Map<String, dynamic>> snap = await FirebaseFirestore
          .instance
          .collection('vouchers')
          .where('isActive', isEqualTo: true)
          .limit(3)
          .get();

      if (snap.docs.isEmpty) {
        return <String, dynamic>{
          'reply':
              'Hiện chưa có voucher khả dụng. Bạn có thể quay lại mục Ví và Khuyến mãi để kiểm tra sau.',
          'suggestions': <Map<String, dynamic>>[],
        };
      }

      final List<String> codes = snap.docs
          .map((d) => (d.data()['code'] ?? '').toString())
          .where((c) => c.trim().isNotEmpty)
          .toList();
      return <String, dynamic>{
        'reply':
            'Voucher đang có: ${codes.join(', ')}. Bạn có thể áp dụng tại bước thanh toán.',
        'suggestions': <Map<String, dynamic>>[],
      };
    }

    if (l.contains('gợi ý') ||
        l.contains('combo') ||
        l.contains('ăn gì') ||
        l.contains('đề xuất') ||
        l.contains('trend') ||
        l.contains('cay')) {
      final QuerySnapshot<Map<String, dynamic>> sellersSnap =
          await FirebaseFirestore.instance.collection('users').get();
      final Set<String> activeSellerIds = sellersSnap.docs
          .where((doc) {
            final Map<String, dynamic> data = doc.data();
            final String role = (data['role'] ?? '').toString();
            final bool isDisabled = (data['isDisabled'] as bool?) ?? false;
            return role == 'seller' && !isDisabled;
          })
          .map((doc) => doc.id)
          .toSet();

      final QuerySnapshot<Map<String, dynamic>> snap = await FirebaseFirestore
          .instance
          .collection('foods')
          .where('isAvailable', isEqualTo: true)
          .limit(40)
          .get();

      final List<Map<String, dynamic>> suggestions = snap.docs
          .map((doc) {
            final Map<String, dynamic> data = doc.data();
            data['foodId'] = doc.id;
            return data;
          })
          .where((data) {
            final String sellerId = (data['sellerId'] ?? '').toString();
            return sellerId.isNotEmpty && activeSellerIds.contains(sellerId);
          })
          .map(_mapFoodToSuggestion)
          .toList();

      final List<Map<String, dynamic>> filteredSuggestions =
          _filterSuggestionsByPrompt(prompt: input, suggestions: suggestions);

      if (filteredSuggestions.isEmpty) {
        return <String, dynamic>{
          'reply':
              'Hiện chưa có món nào từ cửa hàng đang bán để gợi ý cho bạn.',
          'suggestions': <Map<String, dynamic>>[],
        };
      }

      final List<String> top = filteredSuggestions
          .take(3)
          .map(
            (s) =>
                '${s['name']} (${_formatPrice((s['price'] as num?)?.toDouble() ?? 0)})',
          )
          .toList();

      return <String, dynamic>{
        'reply':
            'Gợi ý từ các cửa hàng đang bán: ${top.join(', ')}. Bạn có thể xem chi tiết trong phần gợi ý dưới đây.',
        'suggestions': filteredSuggestions,
      };
    }

    if (l.contains('đơn') || l.contains('order') || l.contains('trạng thái')) {
      return <String, dynamic>{
        'reply':
            'Bạn có thể xem trạng thái đơn ở mục Lịch sử đơn hàng. Nếu cần, mình sẽ hướng dẫn theo từng trạng thái: chờ xác nhận, đang chuẩn bị, đang giao, đã giao.',
        'suggestions': <Map<String, dynamic>>[],
      };
    }

    return <String, dynamic>{
      'reply': _fallbackReply(input),
      'suggestions': <Map<String, dynamic>>[],
    };
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;

    final String cleaned = text.trim();
    _controller.clear();
    await _appendMessage(role: 'user', text: cleaned);

    setState(() => _isTyping = true);

    N8nChatbotResponse? response;
    try {
      response = await _n8nService.ask(
        message: cleaned,
        userId: FirebaseAuth.instance.currentUser?.uid ?? 'guest',
        history: _historyForN8n(),
      );
    } catch (_) {
      response = null;
    }

    if (!mounted) return;

    setState(() => _isTyping = false);

    if (response != null) {
      final List<Map<String, dynamic>> filteredSuggestions =
          _filterSuggestionsByPrompt(
            prompt: cleaned,
            suggestions: response.suggestions,
          );
      await _appendMessage(
        role: 'bot',
        text: response.reply,
        hasCard: filteredSuggestions.isNotEmpty,
        foodSuggestions: filteredSuggestions,
      );
      return;
    }

    String fallback;
    List<Map<String, dynamic>> fallbackSuggestions = <Map<String, dynamic>>[];
    try {
      final result = await _smartFallbackReply(cleaned);
      fallback = (result['reply'] ?? '').toString();
      fallbackSuggestions = _normalizeSuggestions(result['suggestions']);
    } catch (_) {
      fallback = _fallbackReply(cleaned);
    }

    await _appendMessage(
      role: 'bot',
      text: fallback,
      hasCard: fallbackSuggestions.isNotEmpty,
      foodSuggestions: fallbackSuggestions,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Chef',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _n8nService.isConfigured
                      ? 'n8n AI đang kết nối'
                      : 'Chế độ dự phòng (rule-based)',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openHistorySheet,
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Xem lịch sử',
          ),
          IconButton(
            onPressed: _messages.length <= 1 ? null : _clearHistory,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Xóa lịch sử',
          ),
        ],
      ),
      body: _isLoadingHistory
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (_isTyping && i == _messages.length) {
                        return _typingDots();
                      }
                      final msg = _messages[i];
                      final bool isBot = msg['role'] == 'bot';
                      final List<Map<String, dynamic>> suggestions =
                          _normalizeSuggestions(msg['foodSuggestions']);
                      return Column(
                        children: [
                          isBot
                              ? _botBubble(
                                  msg['text'] as String,
                                  msg['time'] as String,
                                )
                              : _userBubble(
                                  msg['text'] as String,
                                  msg['time'] as String,
                                ),
                          if (isBot && suggestions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _foodSuggestionsRow(suggestions),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                if (_messages.length <= 2)
                  Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _chip('Goi y combo cho 2 nguoi budget 200k'),
                        _chip('Tìm món ít cay, dễ ăn buổi tối'),
                        _chip('Món nào đang trend hôm nay?'),
                      ],
                    ),
                  ),
                _inputBar(),
              ],
            ),
    );
  }

  Widget _chip(String text) {
    return GestureDetector(
      onTap: () => _send(text),
      child: Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _botBubble(String text, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _userBubble(String text, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typingDots() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => _animDot(i * 150)),
        ),
      ),
    );
  }

  Widget _animDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.4 + v * 0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _foodSuggestionsRow(List<Map<String, dynamic>> suggestions) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 200,
        child: ListView.separated(
          padding: const EdgeInsets.only(bottom: 10),
          scrollDirection: Axis.horizontal,
          itemCount: suggestions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) =>
              _foodSuggestionCard(suggestions[index]),
        ),
      ),
    );
  }

  Widget _foodSuggestionCard(Map<String, dynamic> suggestion) {
    final String foodId = (suggestion['foodId'] ?? '').toString();
    final String name = (suggestion['name'] ?? 'Mon goi y').toString();
    final String category = (suggestion['category'] ?? '').toString();
    final String reason = (suggestion['reason'] ?? '').toString();
    final double rating = suggestion['rating'] is num
        ? (suggestion['rating'] as num).toDouble()
        : 0;
    final double price = suggestion['price'] is num
        ? (suggestion['price'] as num).toDouble()
        : 0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (foodId.isEmpty) {
          _showSnack('Món này chưa có liên kết mua trực tiếp.');
          return;
        }
        Navigator.pushNamed(
          context,
          AppRoutes.foodDetail,
          arguments: FoodDetailRouteArgs(foodId: foodId),
        );
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: 64,
                color: const Color(0xFFF6F6F6),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppTheme.primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category.isEmpty ? 'Combo de xuat' : category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (rating > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatPrice(price),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) => _send(value),
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF0F0F0),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _send(_controller.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
