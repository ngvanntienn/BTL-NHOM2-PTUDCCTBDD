import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voucher_model.dart';

class VoucherProvider with ChangeNotifier {
  List<VoucherModel> _vouchers = [];

  void _safeNotifyListeners() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    final isBuilding =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks;

    if (isBuilding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) {
          notifyListeners();
        }
      });
      return;
    }

    notifyListeners();
  }

  List<VoucherModel> get vouchers => [..._vouchers];

  Future<void> fetchVouchers() async {
    final snap = await FirebaseFirestore.instance
        .collection('vouchers')
        .where('isActive', isEqualTo: true)
        .get();

    _vouchers = snap.docs
        .map((d) => VoucherModel.fromMap(d.data(), d.id))
        .where((v) => v.canUse)
        .toList();
    _safeNotifyListeners();
  }
}
