import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voucher_model.dart';

class VoucherProvider with ChangeNotifier {
  List<VoucherModel> _vouchers = [];

  List<VoucherModel> get vouchers => [..._vouchers];

  Future<void> fetchVouchers() async {
    final snap = await FirebaseFirestore.instance
        .collection('vouchers')
        .where('isActive', isEqualTo: true)
        .get();

    _vouchers = snap.docs.map((d) => VoucherModel.fromMap(d.data(), d.id)).toList();
    notifyListeners();
  }
}
