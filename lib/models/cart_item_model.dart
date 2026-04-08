import 'product_model.dart';

class CartItemModel {
  final ProductModel product;
  int quantity;
  String? note;

  CartItemModel({
    required this.product,
    this.quantity = 1,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'productName': product.name,
      'price': product.price,
      'imageUrl': product.imageUrl,
      'quantity': quantity,
      'note': note,
    };
  }

  double get totalPrice => product.price * quantity;
}
