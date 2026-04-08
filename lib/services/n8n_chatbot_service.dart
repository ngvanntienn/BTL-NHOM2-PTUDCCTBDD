import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class N8nChatbotResponse {
  const N8nChatbotResponse({required this.reply, required this.suggestions});

  final String reply;
  final List<Map<String, dynamic>> suggestions;
}

class N8nChatbotService {
  N8nChatbotService({String? webhookUrl, http.Client? client})
    : _webhookUrl =
          webhookUrl ?? const String.fromEnvironment('N8N_CHATBOT_WEBHOOK'),
      _openAiApiKey = const String.fromEnvironment('OPENAI_API_KEY'),
      _openAiModel = const String.fromEnvironment(
        'OPENAI_MODEL',
        defaultValue: 'gpt-4o-mini',
      ),
      _openAiBaseUrl = const String.fromEnvironment(
        'OPENAI_BASE_URL',
        defaultValue: 'https://api.openai.com/v1',
      ),
      _client = client ?? http.Client();

  final String _webhookUrl;
  final String _openAiApiKey;
  final String _openAiModel;
  final String _openAiBaseUrl;
  final http.Client _client;

  bool get isConfigured => _openAiApiKey.isNotEmpty || _webhookUrl.isNotEmpty;

  Future<N8nChatbotResponse?> ask({
    required String message,
    required String userId,
    required List<Map<String, dynamic>> history,
  }) async {
    if (_openAiApiKey.isNotEmpty) {
      try {
        final N8nChatbotResponse response = await _askOpenAi(
          message: message,
          history: history,
        );
        return response;
      } catch (_) {
        // Fall through to n8n when LLM endpoint fails.
      }
    }

    if (_webhookUrl.isNotEmpty) {
      return _askN8n(message: message, userId: userId, history: history);
    }

    return null;
  }

  Future<N8nChatbotResponse> _askOpenAi({
    required String message,
    required List<Map<String, dynamic>> history,
  }) async {
    final Uri uri = Uri.parse('$_openAiBaseUrl/chat/completions');

    final List<Map<String, String>> msgs = <Map<String, String>>[
      <String, String>{
        'role': 'system',
        'content':
            'Bạn là AI Chef cho ứng dụng giao đồ ăn. Trả lời tiếng Việt có dấu, đúng trọng tâm, ngắn gọn 3-6 câu. '
            'Ưu tiên gợi ý thực tế, có cấu trúc rõ ràng, tránh lan man. Nếu thiếu dữ liệu thì nói thẳng điều còn thiếu.',
      },
      ...history.map((Map<String, dynamic> item) {
        final String role = (item['role'] ?? 'user').toString();
        final String content = (item['text'] ?? '').toString();
        return <String, String>{
          'role': role == 'bot' ? 'assistant' : 'user',
          'content': content,
        };
      }),
      <String, String>{'role': 'user', 'content': message},
    ];

    final Map<String, dynamic> payload = <String, dynamic>{
      'model': _openAiModel,
      'messages': msgs,
      'temperature': 0.4,
      'max_tokens': 500,
    };

    final http.Response response = await _client
        .post(
          uri,
          headers: <String, String>{
            'Authorization': 'Bearer $_openAiApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('LLM failed: ${response.statusCode}');
    }

    final String utf8Body = utf8.decode(
      response.bodyBytes,
      allowMalformed: true,
    );
    final dynamic decoded = jsonDecode(utf8Body);
    final List<dynamic> choices =
        (decoded['choices'] as List<dynamic>?) ?? <dynamic>[];
    if (choices.isEmpty) {
      throw StateError('LLM empty response');
    }

    final Map<String, dynamic> first = (choices.first as Map)
        .cast<String, dynamic>();
    final Map<String, dynamic> msg =
        ((first['message'] as Map?) ?? <String, dynamic>{})
            .cast<String, dynamic>();
    final String content = (msg['content'] ?? '').toString().trim();
    if (content.isEmpty) {
      throw StateError('LLM blank response');
    }

    return N8nChatbotResponse(
      reply: content,
      suggestions: const <Map<String, dynamic>>[],
    );
  }

  Future<N8nChatbotResponse?> _askN8n({
    required String message,
    required String userId,
    required List<Map<String, dynamic>> history,
  }) async {
    final Uri uri = Uri.parse(_webhookUrl);
    final Map<String, dynamic> payload = <String, dynamic>{
      'message': message,
      'userId': userId,
      'locale': 'vi-VN',
      'history': history,
      'context': <String, dynamic>{'intent': 'food_combo_recommendation'},
    };

    final http.Response response = await _client
        .post(
          uri,
          headers: <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('n8n webhook failed: ${response.statusCode}');
    }

    final String utf8Body = utf8.decode(
      response.bodyBytes,
      allowMalformed: true,
    );
    final dynamic decoded = jsonDecode(utf8Body);
    return _parseResponse(decoded);
  }

  N8nChatbotResponse _parseResponse(dynamic decoded) {
    if (decoded is List && decoded.isNotEmpty) {
      return _parseResponse(decoded.first);
    }

    if (decoded is! Map<String, dynamic>) {
      return const N8nChatbotResponse(
        reply: 'Xin lỗi, hệ thống AI đang bận. Bạn thử lại sau nhé.',
        suggestions: <Map<String, dynamic>>[],
      );
    }

    final Map<String, dynamic> root = decoded;
    final Map<String, dynamic> data = root['data'] is Map<String, dynamic>
        ? root['data'] as Map<String, dynamic>
        : root;

    final String reply =
        _firstNonEmptyString(<dynamic>[
          data['reply'],
          data['answer'],
          data['text'],
          data['message'],
        ]) ??
        'Mình đã nhận câu hỏi của bạn. Bạn có thể mô tả rõ hơn món bạn muốn tìm?';

    final List<Map<String, dynamic>> suggestions = _parseSuggestions(
      data['suggestions'] ??
          data['foods'] ??
          data['comboFoods'] ??
          data['trendingFoods'],
    );

    return N8nChatbotResponse(reply: reply, suggestions: suggestions);
  }

  List<Map<String, dynamic>> _parseSuggestions(dynamic raw) {
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];

    for (final dynamic element in raw) {
      if (element is! Map<String, dynamic>) {
        continue;
      }

      final String name =
          _firstNonEmptyString(<dynamic>[
            element['name'],
            element['title'],
            element['foodName'],
          ]) ??
          'Mon goi y';
      final String category = (element['category'] ?? '').toString();
      final String reason = (element['reason'] ?? element['note'] ?? '')
          .toString();
      final double price = _toDouble(element['price']);
      final double rating = _toDouble(element['rating']);

      items.add(<String, dynamic>{
        'name': name,
        'category': category,
        'reason': reason,
        'price': price,
        'rating': rating,
      });
    }

    return items;
  }

  String? _firstNonEmptyString(List<dynamic> values) {
    for (final dynamic value in values) {
      final String text = (value ?? '').toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }
}
