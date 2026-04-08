import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/address_model.dart';

class AddressProvider with ChangeNotifier {
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;

  List<AddressModel> get addresses => [..._addresses];
  AddressModel? get selectedAddress => _selectedAddress;

  Future<void> fetchAddresses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .get();

    _addresses = snap.docs.map((d) => AddressModel.fromMap(d.data(), d.id)).toList();
    if (_addresses.isNotEmpty) {
      _selectedAddress = _addresses.firstWhere((a) => a.isDefault, orElse: () => _addresses.first);
    }
    notifyListeners();
  }

  Future<void> addAddress(String label, String receiverName, String phoneNumber, String detail, bool isDefault) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc();

    final newAddr = AddressModel(
      id: docRef.id, 
      label: label, 
      receiverName: receiverName, 
      phoneNumber: phoneNumber, 
      detail: detail, 
      isDefault: isDefault
    );

    if (isDefault) await _clearDefaults(uid);

    await docRef.set(newAddr.toMap());
    await fetchAddresses();
  }

  Future<void> updateAddress(AddressModel updated) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (updated.isDefault) await _clearDefaults(uid);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(updated.id)
        .update(updated.toMap());
    await fetchAddresses();
  }

  Future<void> deleteAddress(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(id)
        .delete();
    await fetchAddresses();
  }

  Future<void> _clearDefaults(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    for (var a in _addresses) {
      if (a.isDefault) {
        batch.update(FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('addresses')
            .doc(a.id), {'isDefault': false});
      }
    }
    await batch.commit();
  }

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }
}
