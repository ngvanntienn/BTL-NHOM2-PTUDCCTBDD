class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String foods = 'foods';
  static const String orders = 'orders';
  static const String categories = 'categories';
  static const String reviews = 'reviews';
  static const String favorites = 'favorites';
  static const String sellerInterviewAttempts = 'seller_interview_attempts';
  static const String sellerRewards = 'seller_rewards';
}

class FirestoreOrderStatus {
  FirestoreOrderStatus._();

  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String preparing = 'preparing';
  static const String shipping = 'shipping';
  static const String delivered = 'delivered';
  static const String rejected = 'rejected';
  static const String cancelled = 'cancelled';
}
