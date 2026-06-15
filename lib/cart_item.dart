class CartItem {
  final int drugId;
  final String name;
  final double price;
  final String offer; // 👈 إضافة حقل العرض
  int quantity;

  CartItem({
    required this.drugId,
    required this.name,
    required this.price,
    required this.offer, // 👈 جعله مطلوباً
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      "drug_id": drugId,
      "name": name,
      "price": price,
      "offer": offer, // 👈 ليتم إرساله للسيرفر وتخزينه في قاعدة البيانات
      "quantity": quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      drugId: json["drug_id"] ?? 0,
      name: json["name"] ?? "",
      price: (json["price"] ?? 0).toDouble(),
      offer: json["offer"] ?? "لا يوجد عرض", // 👈 لاسترجاعه من الذاكرة
      quantity: json["quantity"] ?? 1,
    );
  }
}
