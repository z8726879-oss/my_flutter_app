import 'package:flutter/material.dart';

class RequestDetailsScreen extends StatelessWidget {
  final int requestId;
  final List<dynamic> items;

  const RequestDetailsScreen({
    super.key,
    required this.requestId,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // خلفية طبية هادئة وفخمة
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          "تفاصيل الفاتورة الموثقة #$requestId",
          style: const TextStyle(
              color: Color(0xFF007A87),
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF007A87), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: items.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                // --- استخراج البيانات مع حماية فائقة ضد القيم الفارغة ---
                final String drugName = item["drug_name"] ?? "مستحضر غير معروف";
                final int quantity = item["quantity"] ?? 0;

                // جلب السعر (يدعم الاسم البرمجي price أو price_at_purchase)
                final double price = double.parse(
                    (item["price"] ?? item["price_at_purchase"] ?? 0)
                        .toString());

                // جلب العرض (يدعم الاسم البرمجي offer أو offer_at_purchase)
                final String offer =
                    (item["offer"] ?? item["offer_at_purchase"] ?? "")
                        .toString();

                return _buildItemCard(drugName, quantity, price, offer);
              },
            ),
    );
  }

  // مكوّن بناء كرت الدواء مع تفاصيل العروض والأسعار
  Widget _buildItemCard(String name, int qty, double price, String offer) {
    // التحقق من وجود عرض حقيقي (مثل 6+1) لإظهاره
    bool hasOffer = offer.isNotEmpty &&
        offer != "null" &&
        offer != "لا يوجد عرض" &&
        offer != "0";

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // السطر الأول: الاسم والكمية
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: const Color(0xFF007A87).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "الكمية: x$qty",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007A87),
                        fontFamily: 'Cairo',
                        fontSize: 13),
                  ),
                ),
                Expanded(
                  child: Text(
                    name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Cairo',
                        color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),

            // السطر الثاني: تفاصيل السعر
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("إجمالي البند",
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontFamily: 'Cairo')),
                    Text(
                      "${(price * qty).toStringAsFixed(0)} ل.س",
                      style: const TextStyle(
                          color: Color(0xFF10B981), // الأخضر المالي
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("سعر العلبة المثبت",
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontFamily: 'Cairo')),
                    Text(
                      "${price.toStringAsFixed(0)} ل.س",
                      style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ],
            ),

            // --- السطر الثالث: منطقة العروض (Bonus Zone) ---
            if (hasOffer)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      // ignore: deprecated_member_use
                      border:
                          // ignore: deprecated_member_use
                          Border.all(color: Colors.orange.withOpacity(0.2))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        offer,
                        style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo'),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.card_giftcard_rounded,
                          color: Colors.orange, size: 16),
                      const Text(
                        " :العرض المرفق ",
                        style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontFamily: 'Cairo'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "لا توجد تفاصيل متاحة لهذا الطلب",
        style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
      ),
    );
  }
}
