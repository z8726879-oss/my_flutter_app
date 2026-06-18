import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'cart_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool isLoading = false;

  // ==========================================
  // 1. حذف عنصر وتحديث الواجهة والمجموع
  // ==========================================
  void removeItem(int drugId) async {
    await CartService.removeItem(drugId);
    setState(() {}); // إعادة بناء الشاشة لتحديث المجموع المالي والعدد
  }

  // ==========================================
  // 2. تعديل الكمية ومزامنة الحساب المالي
  // ==========================================
  void changeQty(int index, int change) async {
    setState(() {
      CartService.items[index].quantity += change;
    });
    if (CartService.items[index].quantity <= 0) {
      await CartService.removeItem(CartService.items[index].drugId);
    } else {
      await CartService.saveCart(); // حفظ في SharedPreferences
    }
    setState(() {}); // تحديث الفاتورة المالية الإجمالية
  }

  // ==========================================
  // 3. إرسال الطلب (المعالج المحترف لضمان الظهور في الطلبات)
  // ==========================================
  Future<void> sendOrder() async {
    if (CartService.items.isEmpty) return;
    final pharmacyId = AuthService.currentPharmacy?['id'];
    if (pharmacyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("فشل تحديد الهوية، يرجى إعادة تسجيل الدخول"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    setState(() => isLoading = true);
    try {
      final orderItems =
          CartService.items.map((item) => item.toJson()).toList();
      await ApiService.createRequest(
        pharmacyId: pharmacyId,
        items: orderItems,
      );
      await CartService.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Text(
                "تم تثبيت وإرسال طلبيتك بنجاح، تابعها في صفحة الطلبات 🚀",
                style: TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("فشل تسليم الطلب: $e",
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = CartService.items;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "سلة طلبيتك الحالية",
          style: TextStyle(
              color: Color(0xFF007A87),
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF007A87)))
          : items.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) =>
                            _buildCartCard(items[index], index),
                      ),
                    ),
                    _buildBottomSummary(),
                  ],
                ),
    );
  }

  // --- تصميم كرت الدواء المطور لمنع تداخل النصوص ---
  Widget _buildCartCard(dynamic item, int index) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          textDirection:
              TextDirection.rtl, // لضمان الترتيب الصحيح من اليمين لليسار
          children: [
            // 1. أيقونة الدواء اليمنى
            CircleAvatar(
              backgroundColor: const Color(0xFF007A87).withOpacity(0.08),
              child: const Icon(Icons.medication_rounded,
                  color: Color(0xFF007A87)),
            ),
            const SizedBox(width: 12),

            // 2. قسم النصوص المرن (يمنع تداخل الكلمات أفقياً وعمودياً)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "السعر: ${item.price ?? 0} ل.س",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  if (item.offer != null &&
                      item.offer.isNotEmpty &&
                      item.offer != "لا يوجد عرض") ...[
                    const SizedBox(height: 2),
                    Text(
                      "العرض المرفق: ${item.offer}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 3. قسم أزرار التحكم والعداد (يسار الكرت)
            Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.ltr,
              children: [
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.grey, size: 22),
                  onPressed: () => changeQty(index, -1),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    "${item.quantity}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  icon: const Icon(Icons.add_circle_outline,
                      color: Color(0xFF007A87), size: 22),
                  onPressed: () => changeQty(index, 1),
                ),
                const SizedBox(width: 6),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 22),
                  onPressed: () => removeItem(item.drugId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- اللوحة السفلية (المجموع وتثبيت الطلب المحمي من التداخل) ---
  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        // 💡 حماية الزر من التداخل مع شريط أندرويد السفلي
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${CartService.getTotalPrice().toStringAsFixed(0)} ل.س",
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                      fontFamily: 'Cairo'),
                ),
                const Text("إجمالي قيمة الفاتورة:",
                    style: TextStyle(
                        fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${CartService.getCartCount()} مستحضر",
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const Text("عدد المواد:",
                    style: TextStyle(
                        color: Colors.grey, fontSize: 13, fontFamily: 'Cairo')),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : sendOrder,
                icon: const Icon(Icons.send_rounded,
                    size: 18, color: Colors.white),
                label: const Text(
                  "تثبيت وإرسال الطلب للمستودع",
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007A87),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- واجهة السلة الفارغة المنسقة ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined,
              size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          const Text(
            "سلة مشترياتك فارغة حالياً 🛒",
            style: TextStyle(
                fontSize: 16, fontFamily: 'Cairo', color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
