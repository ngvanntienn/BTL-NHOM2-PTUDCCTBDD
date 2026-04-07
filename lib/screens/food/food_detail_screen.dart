import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/food_model.dart';
import '../../models/food_review_model.dart';
import '../../theme/app_theme.dart';

class FoodDetailScreen extends StatefulWidget {
  const FoodDetailScreen({super.key, required this.foodId});

  final String foodId;

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  DocumentReference<Map<String, dynamic>> get _foodRef =>
      FirebaseFirestore.instance.collection('foods').doc(widget.foodId);

  String _formatMoney(double value) => '${value.toStringAsFixed(0)}đ';

  String _timeLabel(DateTime? time) {
    if (time == null) return '--';
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
  }

  Future<void> _syncFoodRating() async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _foodRef.collection('reviews').get();
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snap.docs;

    if (docs.isEmpty) {
      await _foodRef.update(<String, dynamic>{'rating': 0, 'reviewCount': 0});
      return;
    }

    double total = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in docs) {
      final dynamic rating = doc.data()['rating'];
      if (rating is num) {
        total += rating.toDouble();
      }
    }

    final double avg = total / docs.length;
    await _foodRef.update(<String, dynamic>{
      'rating': avg,
      'reviewCount': docs.length,
    });
  }

  Future<void> _saveReview({
    required double rating,
    required String comment,
    String? reviewId,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Bạn cần đăng nhập để đánh giá món ăn.', isError: true);
      return;
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      'userId': user.uid,
      'userName': user.displayName ?? user.email ?? 'Người dùng',
      'rating': rating,
      'comment': comment.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (reviewId == null) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      await _foodRef.collection('reviews').add(payload);
      _showSnack('Đã thêm đánh giá món ăn.');
    } else {
      await _foodRef.collection('reviews').doc(reviewId).update(payload);
      _showSnack('Đã cập nhật đánh giá.');
    }

    await _syncFoodRating();
  }

  Future<void> _deleteReview(String reviewId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa đánh giá?'),
        content: const Text('Đánh giá sẽ bị xóa khỏi món ăn này.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await _foodRef.collection('reviews').doc(reviewId).delete();
    await _syncFoodRating();
    _showSnack('Đã xóa đánh giá.');
  }

  Future<void> _openReviewSheet({FoodReviewModel? review}) async {
    final TextEditingController commentCtrl =
        TextEditingController(text: review?.comment ?? '');
    double rating = review?.rating ?? 5;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    review == null ? 'Thêm đánh giá' : 'Sửa đánh giá',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List<Widget>.generate(5, (index) {
                      final int star = index + 1;
                      return IconButton(
                        onPressed: () => setInnerState(() => rating = star.toDouble()),
                        icon: Icon(
                          star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 30,
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentCtrl,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Nhận xét của bạn',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (commentCtrl.text.trim().isEmpty) {
                          _showSnack('Vui lòng nhập nội dung đánh giá.', isError: true);
                          return;
                        }
                        await _saveReview(
                          rating: rating,
                          comment: commentCtrl.text,
                          reviewId: review?.id,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(review == null ? 'Gửi đánh giá' : 'Cập nhật đánh giá'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    commentCtrl.dispose();
  }

  Future<void> _saveFavorite(FoodModel food) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Bạn cần đăng nhập để lưu món yêu thích.', isError: true);
      return;
    }

    await FirebaseFirestore.instance
        .collection('favorites')
        .doc(user.uid)
        .collection('items')
        .doc(food.id)
        .set(<String, dynamic>{
      'name': food.name,
      'restaurant': food.restaurant,
      'price': food.price,
      'imageUrl': food.imageUrl,
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _showSnack('Đã thêm vào danh sách yêu thích.');
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppTheme.accentColor,
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
        title: const Text('Chi tiết món ăn'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _foodRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          final DocumentSnapshot<Map<String, dynamic>>? doc = snapshot.data;
          if (doc == null || !doc.exists) {
            return const Center(
              child: Text(
                'Không tìm thấy món ăn.',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
            );
          }

          final FoodModel food = FoodModel.fromDoc(doc);

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: food.imageUrl.isNotEmpty
                      ? Image.network(
                          food.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imageFallback(),
                        )
                      : _imageFallback(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              food.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _saveFavorite(food),
                            icon: const Icon(Icons.favorite_border_rounded),
                            color: AppTheme.primaryColor,
                            tooltip: 'Thêm yêu thích',
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        food.restaurant.isEmpty ? 'FoodExpress' : food.restaurant,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          _infoChip(Icons.category_outlined, food.category),
                          _infoChip(Icons.sell_outlined, _formatMoney(food.price)),
                          _infoChip(Icons.local_fire_department_outlined,
                              food.isTrending ? 'Đang thịnh hành' : 'Món thường'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        food.description.isEmpty
                            ? 'Món ăn này chưa có mô tả chi tiết.'
                            : food.description,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24, color: AppTheme.dividerColor),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Đánh giá món ăn',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _openReviewSheet(),
                        icon: const Icon(Icons.rate_review_outlined, size: 16),
                        label: const Text('Thêm đánh giá'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildReviewsSection(food),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsSection(FoodModel food) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _foodRef.collection('reviews').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
          );
        }

        final List<FoodReviewModel> reviews = snapshot.data?.docs
                .map(FoodReviewModel.fromDoc)
                .toList() ??
            <FoodReviewModel>[];

        final double avgRating = reviews.isEmpty
            ? food.rating
            : reviews.map((review) => review.rating).reduce((a, b) => a + b) / reviews.length;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    avgRating == 0 ? '0.0' : avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${reviews.length} đánh giá)',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (reviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Chưa có đánh giá nào cho món này.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ...reviews.map((review) {
                final bool mine = review.userId == currentUid;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              review.userName.isEmpty ? 'Người dùng' : review.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Row(
                            children: <Widget>[
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 2),
                              Text(
                                review.rating.toStringAsFixed(1),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          if (mine)
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openReviewSheet(review: review);
                                }
                                if (value == 'delete') {
                                  _deleteReview(review.id);
                                }
                              },
                              itemBuilder: (_) => const <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(value: 'edit', child: Text('Sửa')),
                                PopupMenuItem<String>(value: 'delete', child: Text('Xóa')),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        review.comment,
                        style: const TextStyle(height: 1.4, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _timeLabel(review.createdAt),
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFF0F0F0),
      child: const Center(
        child: Icon(Icons.fastfood_rounded, size: 56, color: Colors.grey),
      ),
    );
  }
}
