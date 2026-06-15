import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'request_details_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // جلب الطلبات الخاصة بالصيدلية
  Future<void> fetchRequests() async {
    try {
      final int? pharmacyId = AuthService.currentPharmacy?['id'];
      if (pharmacyId == null) return;

      final data = await ApiService.getRequestsByPharmacy(pharmacyId);

      if (mounted) {
        setState(() {
          requests = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // تحديد لون الحالة
  Color _getStatusColor(String status) {
    if (status.contains('مقبول') || status.contains('approved'))
      // ignore: curly_braces_in_flow_control_structures
      return Colors.green;
    if (status.contains('مرفوض') || status.contains('rejected'))
      // ignore: curly_braces_in_flow_control_structures
      return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "سجل طلباتي",
          style: TextStyle(
              fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF007A87)))
          : requests.isEmpty
              ? const Center(
                  child: Text("لا توجد طلبات سابقة",
                      style: TextStyle(fontFamily: 'Cairo')))
              : RefreshIndicator(
                  onRefresh: fetchRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];

                      // معالجة التاريخ والوقت بشكل آمن
                      final String fullDate =
                          request["created_at"]?.toString() ?? "";
                      final String datePart = fullDate.length >= 10
                          ? fullDate.substring(0, 10)
                          : "غير معروف";
                      final String timePart = fullDate.length >= 16
                          ? fullDate.substring(11, 16)
                          : "";

                      // جلب إجمالي مبلغ الفاتورة
                      final String totalPrice =
                          request["total_price"]?.toString() ?? "0";

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 0,
                        // 👈 الإصلاح هنا: الـ side داخل الـ shape
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "طلب رقم: #${request["id"]}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time,
                                              size: 12,
                                              color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            "$datePart | $timePart",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                              fontFamily: 'Cairo',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  // عرض المبلغ والحالة
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "$totalPrice ل.س",
                                        style: const TextStyle(
                                          color: Color(0xFF007A87),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          fontFamily: 'Cairo',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                                  request["status"])
                                              // ignore: deprecated_member_use
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          request["status"] ?? "قيد الانتظار",
                                          style: TextStyle(
                                            color: _getStatusColor(
                                                request["status"]),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                            fontFamily: 'Cairo',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              // زر عرض التفاصيل
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.receipt_long_outlined,
                                      size: 18),
                                  label: const Text(
                                    "عرض تفاصيل الأصناف",
                                    style: TextStyle(fontFamily: 'Cairo'),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    foregroundColor: const Color(0xFF007A87),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RequestDetailsScreen(
                                          requestId: request["id"] ?? 0,
                                          items:
                                              List.from(request["items"] ?? []),
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
