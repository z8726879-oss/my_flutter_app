import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'cart_item.dart';

class CartService {
  static List<CartItem> _items = [];

  static List<CartItem> get items => _items;

  // ==========================================
  // 1. جلب محتويات السلة المحفوظة عند فتح التطبيق
  // ==========================================
  static Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString("cart");

      if (data != null) {
        List decoded = jsonDecode(data);
        _items = decoded.map((e) => CartItem.fromJson(e)).toList();
      }
    } catch (e) {
      _items = [];
    }
  }

  // ==========================================
  // 2. حفظ محتويات السلة الحالية دائمًا في ذاكرة الهاتف
  // ==========================================
  static Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _items.map((e) => e.toJson()).toList();
    await prefs.setString("cart", jsonEncode(jsonList));
  }

  // ==========================================
  // 3. إضافة دواء جديد للسلة أو زيادة الكمية
  // ==========================================
  static Future<void> addItem(CartItem item) async {
    int index = _items.indexWhere((e) => e.drugId == item.drugId);

    if (index != -1) {
      _items[index].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    await saveCart();
  }

  // ==========================================
  // 4. حذف دواء معين من السلة
  // ==========================================
  static Future<void> removeItem(int drugId) async {
    _items.removeWhere((e) => e.drugId == drugId);
    await saveCart();
  }

  // ==========================================
  // 5. مسح وتفريغ السلة (بعد تثبيت الطلب بنجاح)
  // ==========================================
  static Future<void> clear() async {
    _items.clear();
    await saveCart();
  }

  // ==========================================
  // 6. حساب إجمالي عدد القطع (للعرض السريع)
  // ==========================================
  static int getCartCount() {
    int totalItems = 0;
    for (var item in _items) {
      totalItems += item.quantity;
    }
    return totalItems;
  }

  // ==========================================
  // 7. التعديل الجديد: حساب المجموع المالي الكلي (Total Amount)
  // ==========================================
  static double getTotalPrice() {
    double total = 0.0;
    for (var item in _items) {
      // الآن item.price أصبح معروفاً ولن يعطي خطأ
      total += (item.quantity * item.price);
    }
    return total;
  }
}
