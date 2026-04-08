class AddressModel {
  final String id;
  final String label; // "Nhà riêng", "Công ty"
  final String receiverName; // Tên người nhận
  final String phoneNumber; // Số điện thoại
  final String detail; // Địa chỉ chi tiết
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.receiverName,
    required this.phoneNumber,
    required this.detail,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'receiverName': receiverName,
      'phoneNumber': phoneNumber,
      'detail': detail,
      'isDefault': isDefault,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map, String id) {
    return AddressModel(
      id: id,
      label: map['label'] ?? '',
      receiverName: map['receiverName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      detail: map['detail'] ?? '',
      isDefault: map['isDefault'] ?? false,
    );
  }
}
