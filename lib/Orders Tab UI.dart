// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'request_details_screen.dart';
// ignore: duplicate_import
import 'services/api_service.dart';
import 'services/auth_service.dart';

class PharmacyOrdersTab extends StatefulWidget {
  const PharmacyOrdersTab({super.key});

  @override
  State<PharmacyOrdersTab> createState() => _PharmacyOrdersTabState();
}

class _PharmacyOrdersTabState extends State<PharmacyOrdersTab> {
  List requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPharmacyRequests();
  }

  // ==========================================
  // جلب طلبات الصيدلية الحالية عبر الـ ApiService
  // ==========================================
  Future<void> fetchPharmacyRequests() async {
    try {
      // 1. جلب معرف الصيدلية الحالي من خدمة الأمان (AuthService)
      final int? pharmacyId = AuthService.currentPharmacy?['id'];

      if (pharmacyId == null) {
        throw Exception(
            "لم يتم التعرف على حساب الصيدلية، يرجى إعادة تسجيل الدخول");
      }

      // 2. استدعاء الدالة المحدثة مع تمرير المعرف
      final data = await ApiService.getRequestsByPharmacy(pharmacyId);

      if (mounted) {
        setState(() {
          requests = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("خطأ: ${e.toString().replaceAll('Exception: ', '')}",
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
        );
      }
    }
  }

  // ==========================================
  // تلوين وتنسيق حالات الطلبات طبياً للصيدلي
  // ==========================================
  Color getStatusColor(String status) {
    switch (status) {
      case "تم القبول":
      case "معتمدة":
      case "approved":
        return const Color(0xFF10B981); // الأخضر للطلبات المقبولة
      case "مرفوضة":
      case "rejected":
        return Colors.redAccent;
      case "جاري Tجهيز":
        return Colors.blueAccent;
      default:
        return Colors.orange; // البرتقالي لحالة معلق وقيد المراجعة
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case "تم القبول":
      case "معتمدة":
      case "approved":
        return "مقبول ومعتمد";
      case "مرفوضة":
      case "rejected":
        return "مرفوض من المستودع";
      case "جاري التجهيز":
        return "جاري التجهيز وشحن الشحنة";
      default:
        return "قيد المراجعة والانتظار";
    }
  }

  // ==========================================
  // واجهة المستخدم (UI Build)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: fetchPharmacyRequests, // ميزة السحب للأسفل لتحديث الحالات
        color: const Color(0xFF007A87),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF007A87)))
            : requests.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          "لا توجد طلبات مرسلة مسبقاً حالياً.",
                          style: TextStyle(
                              fontFamily: 'Cairo',
                              color: Colors.grey,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      final int requestId = request["id"] ?? 0;
                      final String status = request["status"] ?? "pending";
                      final List<dynamic> orderItems = request["items"] ?? [];

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        // التعديل هنا: تغيير المسمى إلى color ليتوافق مع إصدار فلاتر لديك
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1), // الحواف الصحيحة المصلحة
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.end, // اتجاه المحاذاة العربي
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // كارت الحالة الملون والمنسق فخماً
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(status)
                                          // ignore: deprecated_member_use
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      getStatusText(status),
                                      style: TextStyle(
                                        color: getStatusColor(status),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Cairo',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  // رقم وتفاصيل الطلبية
                                  Text(
                                    "طلب مبيعات رقم #$requestId",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // عدد المستحضرات المشمولة بالطلب
                              Text(
                                "يحتوي الطلب على عدد: ${orderItems.length} صنف دوائي مدرج",
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    fontFamily: 'Cairo'),
                              ),

                              const Divider(
                                  height: 24, color: Color(0xFFF1F5F9)),

                              // زر عرض تفاصيل وأصناف الطلبية الفخم
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFF007A87)
                                        // ignore: deprecated_member_use
                                        .withOpacity(0.06),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.visibility_rounded,
                                      color: Color(0xFF007A87), size: 18),
                                  label: const Text(
                                    "مراجعة بنود الفاتورة الطبية",
                                    style: TextStyle(
                                      color: Color(0xFF007A87),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                      fontSize: 13,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RequestDetailsScreen(
                                          requestId: requestId,
                                          items:
                                              orderItems, // تمرير مصفوفة الأدوية الحية مباشرة لسرعة فائقة ودون لود
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
