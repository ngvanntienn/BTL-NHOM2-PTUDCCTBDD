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
      _client = client ?? http.Client();

  final String _webhookUrl;
  final http.Client _client;

  bool get isConfigured => _webhookUrl.isNotEmpty;

  Future<N8nChatbotResponse?> ask({
    required String message,
    required String userId,
    required List<Map<String, dynamic>> history,
  }) async {
    if (!isConfigured) {
      return null;
    }

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

    final dynamic decoded = jsonDecode(response.body);
    return _parseResponse(decoded);
  }

  N8nChatbotResponse _parseResponse(dynamic decoded) {
    if (decoded is List && decoded.isNotEmpty) {
      return _parseResponse(decoded.first);
    }

    if (decoded is! Map<String, dynamic>) {
      return const N8nChatbotResponse(
        reply: 'Xin loi, he thong AI dang ban. Ban thu lai sau nhe.',
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
        'Minh da nhan cau hoi cua ban. Ban co the mo ta ro hon mon ban muon tim?';

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
