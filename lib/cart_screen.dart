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
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        // عند الضغط على الكرت بأكمله أو على زر الكمية تفتح نافذة التحكم
        onTap: () => _showQuantityDialog(item, index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              // السطر الأول: اسم الدواء وزر الكمية (المنبثق)
              Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // اسم الدواء
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        color: Color(0xFF1A202C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // أيقونة الكمية التي تشبه تصميم الفاتورة وتفتح المنبثقة عند الضغط
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: const Color(0xFF007A87).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "الكمية: x${item.quantity}",
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A87),
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Divider(color: Color(0xFFEDF2F7), height: 1),
              ),
              // السطر الثاني: تفاصيل السعر والعروض
              Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // السعر الإجمالي للبند
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "إجمالي البند",
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontFamily: 'Cairo'),
                      ),
                      Text(
                        "${(item.price ?? 0) * item.quantity} ل.س",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF007A87),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  // سعر العلبة المفردة
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "سعر العلبة",
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontFamily: 'Cairo'),
                      ),
                      Text(
                        "${item.price ?? 0} ل.س",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4A5568),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuantityDialog(dynamic item, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // تم إصلاح الخطأ القواعدي هنا (إزالة القوس الزائد وضبط خصائص الـ Container)
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // اسم المنتج في النافذة
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A202C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "تعديل كمية الدواء في السلة",
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 30),

                  // أزرار التحكم الكبيرة
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: TextDirection.rtl,
                    children: [
                      // زر زائد كبير
                      InkWell(
                        onTap: () {
                          changeQty(index, 1);
                          setModalState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: const Color(0xFF007A87).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Color(0xFF007A87), size: 32),
                        ),
                      ),

                      // عرض الكمية الكبيرة
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(
                          "${item.quantity}",
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A202C),
                          ),
                        ),
                      ),

                      // زر ناقص كبير
                      // 1. زر ناقص كبير المصلح بطريقة برمجية مرنة تمنع أخطاء الـ const
                      InkWell(
                        onTap: () {
                          if (item.quantity > 1) {
                            changeQty(index, -1);
                            setModalState(() {});
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(
                                0xFFF1F5F9), // استخدام كود اللون الثابت مباشرة لحل مشكلة السطر 344
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.remove_rounded,
                            // استخدمنا كود اللون مباشرة بصيغة هكس (Hex) ليتوافق مع الـ const الأب تماماً وينتهي الخط الأحمر
                            color: item.quantity > 1
                                ? const Color(0xFF2D3748)
                                : const Color(0xFFCBD5E1),
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // زر الحذف النهائي الأحمر في الأسفل
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF5F5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFFEB2B2)),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        removeItem(item.drugId);
                      },
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent),
                      label: const Text(
                        "حذف الدواء من السلة",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            );
          },
        );
      },
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
            // ignore: deprecated_member_use
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
                  "${CartService.getTotalPrice().toStringAsFixed(1)} ل.س",
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
