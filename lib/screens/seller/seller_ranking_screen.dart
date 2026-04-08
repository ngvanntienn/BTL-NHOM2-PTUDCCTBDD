import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/seller/food_model.dart';
import '../../models/seller/order_model.dart';
import '../../services/firestore_schema.dart';
import '../../theme/app_theme.dart';

class SellerRankingScreen extends StatefulWidget {
  const SellerRankingScreen({super.key});

  @override
  State<SellerRankingScreen> createState() => _SellerRankingScreenState();
}

class _SellerRankingScreenState extends State<SellerRankingScreen> {
  _RankingPeriod _period = _RankingPeriod.daily;
  final Set<String> _applyingRewardSellerIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String currentSellerId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Xếp hạng & thưởng seller')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore
            .collection(FirestoreCollections.users)
            .where('role', isEqualTo: 'seller')
            .snapshots(),
        builder:
            (
              BuildContext context,
              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> sellerSnapshot,
            ) {
              if (sellerSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (sellerSnapshot.hasError) {
                return Center(
                  child: Text('Không tải được seller: ${sellerSnapshot.error}'),
                );
              }

              final List<QueryDocumentSnapshot<Map<String, dynamic>>>
              sellerDocs =
                  sellerSnapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[];

              if (sellerDocs.isEmpty) {
                return const Center(
                  child: Text('Chưa có seller nào trong hệ thống.'),
                );
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: firestore
                    .collection(FirestoreCollections.orders)
                    .snapshots(),
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                      orderSnapshot,
                    ) {
                      if (orderSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (orderSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Không tải được đơn hàng: ${orderSnapshot.error}',
                          ),
                        );
                      }

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: firestore
                            .collection(FirestoreCollections.foods)
                            .snapshots(),
                        builder:
                            (
                              BuildContext context,
                              AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                              foodSnapshot,
                            ) {
                              if (foodSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (foodSnapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Không tải được món ăn: ${foodSnapshot.error}',
                                  ),
                                );
                              }

                              return StreamBuilder<
                                QuerySnapshot<Map<String, dynamic>>
                              >(
                                stream: firestore
                                    .collection(
                                      FirestoreCollections
                                          .sellerInterviewAttempts,
                                    )
                                    .snapshots(),
                                builder:
                                    (
                                      BuildContext context,
                                      AsyncSnapshot<
                                        QuerySnapshot<Map<String, dynamic>>
                                      >
                                      interviewSnapshot,
                                    ) {
                                      if (interviewSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (interviewSnapshot.hasError) {
                                        return Center(
                                          child: Text(
                                            'Không tải được dữ liệu phỏng vấn: ${interviewSnapshot.error}',
                                          ),
                                        );
                                      }

                                      return StreamBuilder<
                                        QuerySnapshot<Map<String, dynamic>>
                                      >(
                                        stream: firestore
                                            .collection(
                                              FirestoreCollections
                                                  .sellerRewards,
                                            )
                                            .snapshots(),
                                        builder:
                                            (
                                              BuildContext context,
                                              AsyncSnapshot<
                                                QuerySnapshot<
                                                  Map<String, dynamic>
                                                >
                                              >
                                              rewardSnapshot,
                                            ) {
                                              if (rewardSnapshot
                                                      .connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              }
                                              if (rewardSnapshot.hasError) {
                                                return Center(
                                                  child: Text(
                                                    'Không tải được dữ liệu thưởng: ${rewardSnapshot.error}',
                                                  ),
                                                );
                                              }

                                              final String periodKey =
                                                  _periodKey(
                                                    _period,
                                                    DateTime.now(),
                                                  );
                                              final Map<String, int>
                                              rewardAppliedBySeller =
                                                  <String, int>{};

                                              for (final QueryDocumentSnapshot<
                                                    Map<String, dynamic>
                                                  >
                                                  doc
                                                  in rewardSnapshot
                                                          .data
                                                          ?.docs ??
                                                      <
                                                        QueryDocumentSnapshot<
                                                          Map<String, dynamic>
                                                        >
                                                      >[]) {
                                                final Map<String, dynamic>
                                                data = doc.data();
                                                final String docPeriod =
                                                    (data['period'] ?? '')
                                                        .toString();
                                                final String docPeriodKey =
                                                    (data['periodKey'] ?? '')
                                                        .toString();
                                                if (docPeriod != _period.name ||
                                                    docPeriodKey != periodKey) {
                                                  continue;
                                                }

                                                final String sellerId =
                                                    (data['sellerId'] ?? '')
                                                        .toString();
                                                final int amount =
                                                    (data['amount'] as num?)
                                                        ?.toInt() ??
                                                    0;
                                                if (sellerId.isEmpty) {
                                                  continue;
                                                }
                                                rewardAppliedBySeller[sellerId] =
                                                    amount;
                                              }

                                              final List<_SellerRankingEntry>
                                              ranking = _buildRanking(
                                                sellerDocs: sellerDocs,
                                                orderDocs:
                                                    orderSnapshot.data?.docs ??
                                                    <
                                                      QueryDocumentSnapshot<
                                                        Map<String, dynamic>
                                                      >
                                                    >[],
                                                foodDocs:
                                                    foodSnapshot.data?.docs ??
                                                    <
                                                      QueryDocumentSnapshot<
                                                        Map<String, dynamic>
                                                      >
                                                    >[],
                                                interviewDocs:
                                                    interviewSnapshot
                                                        .data
                                                        ?.docs ??
                                                    <
                                                      QueryDocumentSnapshot<
                                                        Map<String, dynamic>
                                                      >
                                                    >[],
                                                period: _period,
                                              );

                                              return Column(
                                                children: <Widget>[
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.fromLTRB(
                                                          16,
                                                          14,
                                                          16,
                                                          0,
                                                        ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: <Widget>[
                                                        _periodSelector(),
                                                        const SizedBox(
                                                          height: 10,
                                                        ),
                                                        _rewardSummary(ranking),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Expanded(
                                                    child: ListView.separated(
                                                      padding:
                                                          const EdgeInsets.fromLTRB(
                                                            16,
                                                            0,
                                                            16,
                                                            24,
                                                          ),
                                                      itemCount: ranking.length,
                                                      separatorBuilder:
                                                          (_, __) =>
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                      itemBuilder:
                                                          (
                                                            BuildContext
                                                            context,
                                                            int index,
                                                          ) {
                                                            final _SellerRankingEntry
                                                            entry =
                                                                ranking[index];
                                                            final int rank =
                                                                index + 1;
                                                            final int reward =
                                                                _rewardByRank(
                                                                  rank,
                                                                  _period,
                                                                );
                                                            final bool
                                                            isCurrentSeller =
                                                                currentSellerId
                                                                    .isNotEmpty &&
                                                                entry.sellerId ==
                                                                    currentSellerId;
                                                            final bool
                                                            rewardApplied =
                                                                rewardAppliedBySeller
                                                                    .containsKey(
                                                                      entry
                                                                          .sellerId,
                                                                    );
                                                            final int
                                                            appliedAmount =
                                                                rewardAppliedBySeller[entry
                                                                    .sellerId] ??
                                                                0;

                                                            return _rankingCard(
                                                              rank: rank,
                                                              entry: entry,
                                                              reward: reward,
                                                              appliedAmount:
                                                                  appliedAmount,
                                                              rewardApplied:
                                                                  rewardApplied,
                                                              isCurrentSeller:
                                                                  isCurrentSeller,
                                                              onApplyReward: () =>
                                                                  _applyReward(
                                                                    entry:
                                                                        entry,
                                                                    rank: rank,
                                                                  ),
                                                            );
                                                          },
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                      );
                                    },
                              );
                            },
                      );
                    },
              );
            },
      ),
    );
  }

  Widget _periodSelector() {
    return Row(
      children: <Widget>[
        _periodChip(_RankingPeriod.daily, 'Thưởng ngày'),
        const SizedBox(width: 8),
        _periodChip(_RankingPeriod.weekly, 'Thưởng tuần'),
        const SizedBox(width: 8),
        _periodChip(_RankingPeriod.monthly, 'Thưởng tháng'),
      ],
    );
  }

  Widget _periodChip(_RankingPeriod value, String label) {
    return ChoiceChip(
      selected: _period == value,
      label: Text(label),
      onSelected: (_) => setState(() => _period = value),
    );
  }

  Widget _rewardSummary(List<_SellerRankingEntry> ranking) {
    final String periodLabel = switch (_period) {
      _RankingPeriod.daily => 'hôm nay',
      _RankingPeriod.weekly => '7 ngày gần nhất',
      _RankingPeriod.monthly => '30 ngày gần nhất',
    };

    final _SellerRankingEntry? top1 = ranking.isNotEmpty ? ranking[0] : null;
    final _SellerRankingEntry? top2 = ranking.length > 1 ? ranking[1] : null;
    final _SellerRankingEntry? top3 = ranking.length > 2 ? ranking[2] : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Quỹ thưởng $periodLabel',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Top 1: ${_rewardByRank(1, _period)} VND ${top1 == null ? '' : '• ${top1.sellerName}'}',
          ),
          Text(
            'Top 2: ${_rewardByRank(2, _period)} VND ${top2 == null ? '' : '• ${top2.sellerName}'}',
          ),
          Text(
            'Top 3: ${_rewardByRank(3, _period)} VND ${top3 == null ? '' : '• ${top3.sellerName}'}',
          ),
          const SizedBox(height: 4),
          const Text(
            'Có thể bấm Cộng thưởng để cộng tiền thưởng vào doanh thu seller.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  List<_SellerRankingEntry> _buildRanking({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> sellerDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> orderDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> foodDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> interviewDocs,
    required _RankingPeriod period,
  }) {
    final Map<String, _SellerAccumulator> statsBySeller =
        <String, _SellerAccumulator>{};

    for (final QueryDocumentSnapshot<Map<String, dynamic>> sellerDoc
        in sellerDocs) {
      final Map<String, dynamic> data = sellerDoc.data();
      final String sellerId = sellerDoc.id;
      statsBySeller[sellerId] = _SellerAccumulator(
        sellerId: sellerId,
        sellerName: (data['name'] ?? 'Seller').toString(),
        bonusRevenue: (data['bonusRevenue'] as num?)?.toDouble() ?? 0,
      );
    }

    final DateTime now = DateTime.now();
    final DateTime cutoff = switch (period) {
      _RankingPeriod.daily => DateTime(now.year, now.month, now.day),
      _RankingPeriod.weekly => now.subtract(const Duration(days: 7)),
      _RankingPeriod.monthly => now.subtract(const Duration(days: 30)),
    };

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in orderDocs) {
      final OrderModel order = OrderModel.fromDoc(doc);
      final _SellerAccumulator? acc = statsBySeller[order.sellerId];
      if (acc == null) {
        continue;
      }

      if (order.updatedAt.isBefore(cutoff)) {
        continue;
      }

      acc.totalOrders += 1;
      if (order.status == OrderStatus.delivered) {
        acc.deliveredOrders += 1;
        acc.deliveredRevenue += order.totalPrice;
      }
    }

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in foodDocs) {
      final FoodModel food = FoodModel.fromDoc(doc);
      final _SellerAccumulator? acc = statsBySeller[food.sellerId];
      if (acc == null) {
        continue;
      }
      if (food.rating > 0) {
        acc.ratingSum += food.rating;
        acc.ratedFoods += 1;
      }
    }

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in interviewDocs) {
      final Map<String, dynamic> data = doc.data();
      final String sellerId = (data['sellerId'] ?? '').toString();
      final _SellerAccumulator? acc = statsBySeller[sellerId];
      if (acc == null) {
        continue;
      }
      acc.completedInterview = true;
      if ((data['passed'] as bool?) ?? false) {
        acc.passedInterview = true;
      }
    }

    final List<_SellerRankingEntry> entries = statsBySeller.values.map((acc) {
      final double avgRating = acc.ratedFoods == 0
          ? 0
          : acc.ratingSum / acc.ratedFoods;

      final double score =
          (acc.deliveredOrders * 15) +
          (avgRating * 12) +
          (acc.deliveredRevenue / 100000) +
          (acc.passedInterview ? 20 : (acc.completedInterview ? 8 : 0));

      return _SellerRankingEntry(
        sellerId: acc.sellerId,
        sellerName: acc.sellerName,
        deliveredOrders: acc.deliveredOrders,
        totalOrders: acc.totalOrders,
        deliveredRevenue: acc.deliveredRevenue,
        bonusRevenue: acc.bonusRevenue,
        avgRating: avgRating,
        completedInterview: acc.completedInterview,
        passedInterview: acc.passedInterview,
        score: score,
      );
    }).toList();

    entries.sort((_SellerRankingEntry a, _SellerRankingEntry b) {
      final int scoreCmp = b.score.compareTo(a.score);
      if (scoreCmp != 0) {
        return scoreCmp;
      }

      final int revenueCmp = b.deliveredRevenue.compareTo(a.deliveredRevenue);
      if (revenueCmp != 0) {
        return revenueCmp;
      }

      return b.deliveredOrders.compareTo(a.deliveredOrders);
    });

    return entries;
  }

  Widget _rankingCard({
    required int rank,
    required _SellerRankingEntry entry,
    required int reward,
    required int appliedAmount,
    required bool rewardApplied,
    required bool isCurrentSeller,
    required Future<void> Function() onApplyReward,
  }) {
    final Color rankColor = switch (rank) {
      1 => const Color(0xFFE6A100),
      2 => const Color(0xFF8A8A8A),
      3 => const Color(0xFFB87333),
      _ => AppTheme.primaryColor,
    };

    final bool canApplyReward = isCurrentSeller && reward > 0 && !rewardApplied;
    final bool applying = _applyingRewardSellerIds.contains(entry.sellerId);
    final double shownRevenue = entry.deliveredRevenue + entry.bonusRevenue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentSeller ? const Color(0xFFFFF4E8) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrentSeller
              ? AppTheme.primaryColor
              : AppTheme.dividerColor,
          width: isCurrentSeller ? 1.4 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rankColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        entry.sellerName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isCurrentSeller)
                      const Text(
                        'Bạn',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Điểm xếp hạng: ${entry.score.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rewardApplied
                      ? 'Đã cộng thưởng: $appliedAmount VND'
                      : 'Thưởng hiện tại: ${reward > 0 ? '$reward VND' : 'Không có'}',
                  style: TextStyle(
                    color: reward > 0 ? Colors.teal : AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đơn giao: ${entry.deliveredOrders}/${entry.totalOrders} • Doanh thu: ${shownRevenue.toStringAsFixed(0)} VND',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rating món: ${entry.avgRating.toStringAsFixed(1)} • Phỏng vấn: ${entry.passedInterview ? 'Đạt' : (entry.completedInterview ? 'Đã làm' : 'Chưa làm')}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                if (isCurrentSeller)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: canApplyReward && !applying
                            ? onApplyReward
                            : null,
                        icon: applying
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_card),
                        label: Text(
                          rewardApplied
                              ? 'Đã cộng thưởng trong kỳ này'
                              : (reward > 0
                                    ? 'Cộng thưởng vào doanh thu'
                                    : 'Chưa đủ hạng nhận thưởng'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyReward({
    required _SellerRankingEntry entry,
    required int rank,
  }) async {
    final int amount = _rewardByRank(rank, _period);
    if (amount <= 0) {
      return;
    }

    if (_applyingRewardSellerIds.contains(entry.sellerId)) {
      return;
    }

    final String? actorId = FirebaseAuth.instance.currentUser?.uid;
    if (actorId == null || actorId.isEmpty) {
      return;
    }

    setState(() => _applyingRewardSellerIds.add(entry.sellerId));

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final String periodKey = _periodKey(_period, DateTime.now());
      final String rewardDocId =
          '${_period.name}_${periodKey}_${entry.sellerId}';
      final DocumentReference<Map<String, dynamic>> rewardRef = firestore
          .collection(FirestoreCollections.sellerRewards)
          .doc(rewardDocId);
      final DocumentReference<Map<String, dynamic>> sellerRef = firestore
          .collection(FirestoreCollections.users)
          .doc(entry.sellerId);

      await firestore.runTransaction((Transaction tx) async {
        final DocumentSnapshot<Map<String, dynamic>> rewardSnap = await tx.get(
          rewardRef,
        );
        if (rewardSnap.exists) {
          throw Exception('Thưởng kỳ này đã được cộng trước đó.');
        }

        tx.set(rewardRef, <String, dynamic>{
          'sellerId': entry.sellerId,
          'period': _period.name,
          'periodKey': periodKey,
          'rank': rank,
          'amount': amount,
          'appliedBy': actorId,
          'appliedAt': FieldValue.serverTimestamp(),
        });

        tx.update(sellerRef, <String, dynamic>{
          'bonusRevenue': FieldValue.increment(amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cộng $amount VND vào doanh thu của bạn.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể cộng thưởng: $e')));
    } finally {
      if (mounted) {
        setState(() => _applyingRewardSellerIds.remove(entry.sellerId));
      }
    }
  }
}

enum _RankingPeriod { daily, weekly, monthly }

String _periodKey(_RankingPeriod period, DateTime date) {
  switch (period) {
    case _RankingPeriod.daily:
      return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    case _RankingPeriod.weekly:
      final DateTime monday = date.subtract(Duration(days: date.weekday - 1));
      return '${monday.year.toString().padLeft(4, '0')}-W${_weekOfYear(monday).toString().padLeft(2, '0')}';
    case _RankingPeriod.monthly:
      return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
  }
}

int _weekOfYear(DateTime date) {
  final DateTime firstDay = DateTime(date.year, 1, 1);
  final int passedDays = date.difference(firstDay).inDays;
  return ((passedDays + firstDay.weekday - 1) / 7).floor() + 1;
}

int _rewardByRank(int rank, _RankingPeriod period) {
  final Map<int, int> rewards = switch (period) {
    _RankingPeriod.daily => <int, int>{1: 50000, 2: 30000, 3: 15000},
    _RankingPeriod.weekly => <int, int>{1: 300000, 2: 200000, 3: 100000},
    _RankingPeriod.monthly => <int, int>{1: 1200000, 2: 800000, 3: 400000},
  };
  return rewards[rank] ?? 0;
}

class _SellerAccumulator {
  _SellerAccumulator({
    required this.sellerId,
    required this.sellerName,
    required this.bonusRevenue,
  });

  final String sellerId;
  final String sellerName;
  final double bonusRevenue;

  int totalOrders = 0;
  int deliveredOrders = 0;
  double deliveredRevenue = 0;
  double ratingSum = 0;
  int ratedFoods = 0;
  bool completedInterview = false;
  bool passedInterview = false;
}

class _SellerRankingEntry {
  _SellerRankingEntry({
    required this.sellerId,
    required this.sellerName,
    required this.deliveredOrders,
    required this.totalOrders,
    required this.deliveredRevenue,
    required this.bonusRevenue,
    required this.avgRating,
    required this.completedInterview,
    required this.passedInterview,
    required this.score,
  });

  final String sellerId;
  final String sellerName;
  final int deliveredOrders;
  final int totalOrders;
  final double deliveredRevenue;
  final double bonusRevenue;
  final double avgRating;
  final bool completedInterview;
  final bool passedInterview;
  final double score;
}
