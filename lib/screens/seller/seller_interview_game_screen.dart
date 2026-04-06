import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/firestore_schema.dart';
import '../../theme/app_theme.dart';

class SellerInterviewGameScreen extends StatefulWidget {
  const SellerInterviewGameScreen({
    super.key,
    this.requireCompletionBeforeContinue = false,
    this.onCompleted,
  });

  final bool requireCompletionBeforeContinue;
  final ValueChanged<bool>? onCompleted;

  @override
  State<SellerInterviewGameScreen> createState() =>
      _SellerInterviewGameScreenState();
}

class _SellerInterviewGameScreenState extends State<SellerInterviewGameScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<_InterviewQuestion> _questions = _defaultQuestions;

  int _currentIndex = 0;
  int _score = 0;
  bool _isFinished = false;
  bool _isSaving = false;
  late final DateTime _startedAt;
  final Map<String, int> _selectedOptionByQuestionId = <String, int>{};

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
  }

  CollectionReference<Map<String, dynamic>> get _attemptsRef =>
      _firestore.collection(FirestoreCollections.sellerInterviewAttempts);

  Future<void> _answer(int selectedOption) async {
    final _InterviewQuestion question = _questions[_currentIndex];

    if (_selectedOptionByQuestionId.containsKey(question.id)) {
      return;
    }

    _selectedOptionByQuestionId[question.id] = selectedOption;
    if (selectedOption == question.correctOptionIndex) {
      _score += 1;
    }

    if (_currentIndex == _questions.length - 1) {
      final bool passed = _score >= (_questions.length * 0.7).ceil();
      setState(() => _isFinished = true);
      if (widget.requireCompletionBeforeContinue && mounted) {
        widget.onCompleted?.call(passed);
      }
      unawaited(_saveAttempt());
      return;
    }

    setState(() => _currentIndex += 1);
  }

  Future<void> _saveAttempt() async {
    if (_isSaving) {
      return;
    }

    final String sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (sellerId.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final DateTime submittedAtClient = DateTime.now();
      final int durationSeconds = DateTime.now()
          .difference(_startedAt)
          .inSeconds;
      final bool passed = _score >= (_questions.length * 0.7).ceil();

      await _attemptsRef.add(<String, dynamic>{
        'sellerId': sellerId,
        'score': _score,
        'totalQuestions': _questions.length,
        'passed': passed,
        'selectedOptionByQuestionId': _selectedOptionByQuestionId,
        'submittedAtClient': Timestamp.fromDate(submittedAtClient),
        'submittedAt': FieldValue.serverTimestamp(),
        'durationSeconds': durationSeconds,
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu kết quả bài phỏng vấn: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _score = 0;
      _isFinished = false;
      _selectedOptionByQuestionId.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final String sellerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return PopScope(
      canPop: !widget.requireCompletionBeforeContinue || _isFinished,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading:
              !widget.requireCompletionBeforeContinue || _isFinished,
          title: const Text('Game phỏng vấn seller mới'),
        ),
        body: sellerId.isEmpty
            ? const Center(child: Text('Không tìm thấy tài khoản người bán.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildHeaderCard(),
                    const SizedBox(height: 12),
                    _isFinished ? _buildResultCard() : _buildQuestionCard(),
                    const SizedBox(height: 20),
                    if (widget.requireCompletionBeforeContinue && !_isFinished)
                      const Text(
                        'Bạn cần hoàn thành bài phỏng vấn trước khi vào trang seller.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    if (!(widget.requireCompletionBeforeContinue &&
                        !_isFinished))
                      const Text(
                        'Lịch sử gần đây (realtime)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    if (!(widget.requireCompletionBeforeContinue &&
                        !_isFinished))
                      const SizedBox(height: 10),
                    if (!(widget.requireCompletionBeforeContinue &&
                        !_isFinished))
                      _buildRealtimeAttemptHistory(sellerId),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final double progress = (_currentIndex + 1) / _questions.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Đánh giá năng lực vận hành shop',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isFinished
                ? 'Bạn đã hoàn thành bài phỏng vấn. Có thể làm lại để luyện thêm.'
                : 'Câu ${_currentIndex + 1}/${_questions.length}',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: _isFinished ? 1 : progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: AppTheme.backgroundColor,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final _InterviewQuestion question = _questions[_currentIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          ...List<Widget>.generate(question.options.length, (int index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _answer(index),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    side: const BorderSide(color: AppTheme.dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    question.options[index],
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final int total = _questions.length;
    final bool passed = _score >= (total * 0.7).ceil();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            passed ? 'Kết quả: Đạt' : 'Kết quả: Chưa đạt',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: passed ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Điểm: $_score/$total',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            passed
                ? 'Bạn có thể vận hành shop với các quy trình cơ bản.'
                : 'Nên ôn lại xử lý đơn hàng, tồn kho và chăm sóc khách trước khi mở bán.',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _restart,
              icon: const Icon(Icons.replay),
              label: const Text('Làm lại bài phỏng vấn'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeAttemptHistory(String sellerId) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _attemptsRef.where('sellerId', isEqualTo: sellerId).snapshots(),
      builder:
          (
            BuildContext context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Text('Không thể tải lịch sử: ${snapshot.error}');
            }

            final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
                snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            docs.sort((
              QueryDocumentSnapshot<Map<String, dynamic>> a,
              QueryDocumentSnapshot<Map<String, dynamic>> b,
            ) {
              final Timestamp? aTs = a.data()['submittedAt'] as Timestamp?;
              final Timestamp? bTs = b.data()['submittedAt'] as Timestamp?;
              final DateTime aDt =
                  aTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
              final DateTime bDt =
                  bTs?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bDt.compareTo(aDt);
            });

            final List<QueryDocumentSnapshot<Map<String, dynamic>>> recentDocs =
                docs.take(5).toList();

            if (recentDocs.isEmpty) {
              return const Text(
                'Bạn chưa có lần làm bài nào.',
                style: TextStyle(color: AppTheme.textSecondary),
              );
            }

            return Column(
              children: recentDocs.map((
                QueryDocumentSnapshot<Map<String, dynamic>> doc,
              ) {
                final Map<String, dynamic> data = doc.data();
                final int score = (data['score'] as num?)?.toInt() ?? 0;
                final int totalQuestions =
                    (data['totalQuestions'] as num?)?.toInt() ??
                    _questions.length;
                final bool passed = (data['passed'] as bool?) ?? false;
                final int durationSeconds =
                    (data['durationSeconds'] as num?)?.toInt() ?? 0;
                final Timestamp? submittedAtTs =
                    data['submittedAt'] as Timestamp?;
                final Timestamp? submittedAtClientTs =
                    data['submittedAtClient'] as Timestamp?;
                final DateTime? submittedAt =
                    submittedAtTs?.toDate() ?? submittedAtClientTs?.toDate();

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: passed
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        child: Icon(
                          passed ? Icons.verified : Icons.error_outline,
                          color: passed ? Colors.green : Colors.red,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Điểm: $score/$totalQuestions • ${passed ? 'Đạt' : 'Chưa đạt'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              submittedAt == null
                                  ? 'Đang cập nhật thời gian...'
                                  : 'Nộp lúc: ${submittedAt.day.toString().padLeft(2, '0')}/${submittedAt.month.toString().padLeft(2, '0')}/${submittedAt.year} ${submittedAt.hour.toString().padLeft(2, '0')}:${submittedAt.minute.toString().padLeft(2, '0')} • ${durationSeconds}s',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
    );
  }
}

class _InterviewQuestion {
  const _InterviewQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
  });

  final String id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
}

const List<_InterviewQuestion> _defaultQuestions = <_InterviewQuestion>[
  _InterviewQuestion(
    id: 'q1',
    question:
        'Khi có đơn mới ở trạng thái chờ xử lý, việc ưu tiên đầu tiên là gì?',
    options: <String>[
      'Đóng app và đợi tài xế gọi',
      'Kiểm tra tồn kho và xác nhận nhận đơn',
      'Tăng giá món để bù phí ship',
      'Nhắn khách tự hủy đơn',
    ],
    correctOptionIndex: 1,
  ),
  _InterviewQuestion(
    id: 'q2',
    question: 'Món ăn nên được tự động ẩn khỏi danh sách khi nào?',
    options: <String>[
      'Khi đánh giá dưới 5 sao',
      'Khi stock về 0 hoặc isAvailable = false',
      'Khi vừa tạo món mới',
      'Khi có hơn 10 đơn/ngày',
    ],
    correctOptionIndex: 1,
  ),
  _InterviewQuestion(
    id: 'q3',
    question: 'Nếu ảnh món upload lỗi tạm thời, xử lý đúng là gì?',
    options: <String>[
      'Lưu món với ảnh rỗng và không báo gì',
      'Bắt lỗi, thông báo rõ cho seller, cho phép thử lại',
      'Xóa tài khoản seller',
      'Đổi sang ảnh của món khác',
    ],
    correctOptionIndex: 1,
  ),
  _InterviewQuestion(
    id: 'q4',
    question: 'Trạng thái hợp lệ sau accepted thường là gì?',
    options: <String>[
      'preparing',
      'pending',
      'rejected',
      'accepted lại lần nữa',
    ],
    correctOptionIndex: 0,
  ),
  _InterviewQuestion(
    id: 'q5',
    question: 'Vì sao cần xử lý đơn bằng transaction khi nhận đơn?',
    options: <String>[
      'Để giao diện đẹp hơn',
      'Để trừ tồn kho nhất quán và tránh race condition',
      'Để giảm màu sắc trong app',
      'Không có lý do đặc biệt',
    ],
    correctOptionIndex: 1,
  ),
  _InterviewQuestion(
    id: 'q6',
    question: 'Realtime Firestore mang lại lợi ích chính nào cho seller?',
    options: <String>[
      'Phải tải lại app mới thấy thay đổi',
      'Tự cập nhật đơn/món ngay khi dữ liệu đổi',
      'Giảm số lượng người dùng',
      'Ẩn toàn bộ dữ liệu cũ',
    ],
    correctOptionIndex: 1,
  ),
  _InterviewQuestion(
    id: 'q7',
    question: 'Khi từ chối đơn, trạng thái phù hợp là?',
    options: <String>['rejected', 'shipping', 'delivered', 'accepted'],
    correctOptionIndex: 0,
  ),
  _InterviewQuestion(
    id: 'q8',
    question: 'Thông tin nào quan trọng khi review hiệu suất vận hành seller?',
    options: <String>[
      'Điểm phỏng vấn, số đơn chờ, doanh thu đã giao',
      'Màu điện thoại của seller',
      'Tuổi của khách hàng',
      'Số lần mở ứng dụng camera',
    ],
    correctOptionIndex: 0,
  ),
];
