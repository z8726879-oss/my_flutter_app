import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart'; // 🌟 السطر الحاسم لتشغيل الكلاس بنجاح

class PharmacyBalanceTab extends StatefulWidget {
  const PharmacyBalanceTab({super.key});

  @override
  State<PharmacyBalanceTab> createState() => _PharmacyBalanceTabState();
}

class _PharmacyBalanceTabState extends State<PharmacyBalanceTab> {
  bool isLoading = true;

  // متغيرات الحساب المالي المربوطة بالسيرفر
  double totalOrdersAmount = 0; // إجمالي قيمة الطلبيات
  double totalPaidAmount = 0; // إجمالي المقبوضات النقدية
  double remainingBalance = 0; // الصافي (الديون المعلقة)

  // قائمة كشف الحساب التفصيلي
  List<Map<String, dynamic>> financialLog = [];

  @override
  void initState() {
    super.initState();
    fetchFinancialData();
  }

  // ==========================================
  // جلب البيانات المالية الحقيقية من السيرفر
  // ==========================================
  Future<void> fetchFinancialData() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);

      // 1. جلب معرف الصيدلية الحالية من AuthService
      final pharmacyId = AuthService.currentPharmacy?['id'];
      if (pharmacyId == null)
        // ignore: curly_braces_in_flow_control_structures
        throw Exception("لم يتم العثور على بيانات الصيدلية");

      // 2. جلب الطلبات والمدفوعات بالتوازي لضمان سرعة الاستجابة
      final results = await Future.wait([
        ApiService.getRequestsByPharmacy(pharmacyId),
        ApiService.getPayments(pharmacyId: pharmacyId),
      ]);

      final List requests = results[0];
      final List payments = results[1];

      double ordersSum = 0;
      double paidSum = 0;
      List<Map<String, dynamic>> combinedLog = [];

      // معالجة الفواتير (تزيد الدين)
      for (var req in requests) {
        if (req['status'] != 'مرفوضة') {
          double val = double.tryParse(req['total_price'].toString()) ?? 0;
          ordersSum += val;
          combinedLog.add({
            "title": "فاتورة طلبية #${req['id']}",
            "date": req['created_at'].toString().substring(0, 10),
            "amount": val,
            "is_plus": true, // تزيد الدين (+)
          });
        }
      }

      // معالجة المقبوضات النقدية (تنقص الدين)
      for (var pay in payments) {
        double val = double.tryParse(pay['amount'].toString()) ?? 0;
        paidSum += val;
        combinedLog.add({
          "title": pay['notes'] ?? "دفعة نقدية للموزع",
          "date": pay['created_at'].toString().substring(0, 10),
          "amount": val,
          "is_plus": false, // تنقص الدين (-)
        });
      }

      // ترتيب السجل من الأحدث للأقدم بناءً على التاريخ
      combinedLog.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
        setState(() {
          totalOrdersAmount = ordersSum;
          totalPaidAmount = paidSum;
          remainingBalance = ordersSum - paidSum;
          financialLog = combinedLog;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("🛑 خطأ مالي: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: fetchFinancialData,
        color: const Color(0xFF007A87),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF007A87)))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 1. لافتة التنبيه المالي
                    _buildWarningBanner(),
                    const SizedBox(height: 16),

                    // 2. كارت ملخص الميزانية الإجمالي
                    _buildBalanceSummaryCard(),
                    const SizedBox(height: 28),

                    // 3. عنوان كشف الحساب
                    const Text(
                      "دفتر حركات كشف الحساب التفصيلي",
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 12),

                    // 4. قائمة حركات كشف الحساب (Timeline)
                    _buildFinancialTimeline(),
                  ],
                ),
              ),
      ),
    );
  }

  // --- الودجت الفرعية المصممة بفخامة ---

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        // ignore: deprecated_member_use
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              "تنويه: الحساب يعتمد الحصيلة النقدية والمقبوضات الورقية اليدوية مع الموزع ولا يدعم الدفع الإلكتروني.",
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
        ],
      ),
    );
  }

  Widget _buildBalanceSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF007A87),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              // ignore: deprecated_member_use
              color: const Color(0xFF007A87).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "الرصيد المتبقي (الديون المعلقة للمستودع)",
            style: TextStyle(
                fontFamily: 'Cairo', color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            // 🌟 تنسيق الرصيد المتبقي بالفواصل والرموز
            "\u200F${NumberFormat('#,##0.0', 'en_US').format(remainingBalance)} ل.س",
            style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Cairo'),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14.0),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 🌟 إرسال الرقم المنسق جاهزاً كـ String للدالة المساعدة
              _buildStatDetail(
                  "المقبوض نقداً",
                  "\u200F${NumberFormat('#,##0.0', 'en_US').format(totalPaidAmount)} ل.س",
                  const Color(0xFF10B981)),
              Container(width: 1, height: 30, color: Colors.white24),
              // 🌟 إرسال الرقم المنسق جاهزاً كـ String للدالة المساعدة
              _buildStatDetail(
                  "إجمالي الطلبيات",
                  "\u200F${NumberFormat('#,##0.0', 'en_US').format(totalOrdersAmount)} ل.س",
                  Colors.white),
            ],
          )
        ],
      ),
    );
  }

// 🌟 تم تعديل المتغير الثاني هنا ليكون String بدلاً من double لكي يقبل النص المنسق بالفواصل
  Widget _buildStatDetail(
      String title, String formattedValue, Color valueColor) {
    return Column(
      children: [
        Text(title,
            style: const TextStyle(
                fontFamily: 'Cairo', color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 2),
        Text(formattedValue,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor,
                fontFamily: 'Cairo')),
      ],
    );
  }

  Widget _buildFinancialTimeline() {
    if (financialLog.isEmpty) {
      return const Center(
        child: Padding(
          // 🌟 التصحيح هنا: استبدال الكلمة المكررة بـ EdgeInsets.only
          padding: EdgeInsets.only(top: 50.0),
          child: Text(
            "لا توجد سجلات مالية حتى الآن",
            style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: financialLog.length,
      itemBuilder: (context, index) {
        final log = financialLog[index];
        final bool isOrder = log["is_plus"];

        // 🌟 تحويل قيمة العملية المالية الحالية وتهيئتها بالفواصل بدقة
        final double amountValue =
            double.tryParse(log["amount"].toString()) ?? 0.0;
        final String formattedAmount =
            NumberFormat('#,##0.0', 'en_US').format(amountValue);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              // القيمة المالية المنسقة داخل السجل لمنع الانعكاس
              Text(
                // 🌟 عرض الإشارة والرقم بالفواصل ثم العملة دون تداخل
                "\u200F${isOrder ? '+' : '-'}$formattedAmount ل.س",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isOrder ? Colors.redAccent : const Color(0xFF10B981),
                  fontFamily: 'Cairo',
                ),
              ),
              const Spacer(),
              // التفاصيل
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    log["title"],
                    style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  Text(log["date"],
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(width: 14),
              // الأيقونة
              CircleAvatar(
                radius: 18,
                backgroundColor: isOrder
                    ? Colors.redAccent.withAlpha(
                        20) // 🌟 استخدام build المستقر بدلاً من الفانكشن المهجورة
                    : const Color(0xFF10B981).withAlpha(20),
                child: Icon(
                  isOrder
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: isOrder ? Colors.redAccent : const Color(0xFF10B981),
                  size: 18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
