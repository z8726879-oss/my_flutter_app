import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart'; // 💡 استيراد كلاس الـ AuthService المطور لحقن التوكن حياً

class ApiService {
  // ==============================================================================
  // ⚙️ الإعدادات الأساسية (Base Configuration)
  // ==============================================================================
  static const String baseUrl = 'http://192.168.43.68:5000/api';

  // 🛡️ [المحرك الأمني الموحد]: حقن وتوزيع التوكن التلقائي على جميع الدوال بالأسفل
  static Map<String, String> get _headers {
    return AuthService.headers;
  }

  // ==============================================================================
  // 1. قطاع الشركات والأدوية (Inventory & Cache System)
  // ==============================================================================

  // ✨ محرك الكاش الذكي (لعلاج بطء الإنترنت)
  static Future<List<dynamic>> getCompaniesWithDrugs() async {
    final prefs = await SharedPreferences.getInstance();
    const String cacheKey = "cached_companies_drugs";

    try {
      // محاولة جلب البيانات حية من السيرفر بمهلة زمنية 10 ثوانٍ
      final response = await http
          .get(Uri.parse("$baseUrl/companies-with-drugs"), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await prefs.setString(cacheKey, response.body);
        return jsonDecode(response.body);
      }
    } catch (e) {
      // ignore: avoid_print
      print(
          "⚠️ الإنترنت ضعيف أو مقطوع، يتم سحب البيانات المخزنة محلياً بالجوال");
    }

    // قراءة البيانات من ذاكرة الجوال المحلية في حال فشل الاتصال بالسيرفر
    String? cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      return jsonDecode(cachedData);
    }
    return [];
  }

  // جلب الشركات الصافي
  static Future<List<dynamic>> getCompanies() async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/companies"), headers: _headers);
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  // إضافة أو تعديل بيانات شركة
  static Future<void> addOrUpdateCompany(
      {int? id, required String name, required String image}) async {
    final url = id == null ? "$baseUrl/companies" : "$baseUrl/companies/$id";
    final body = jsonEncode({"name": name, "image": image});

    final response = id == null
        ? await http.post(Uri.parse(url), headers: _headers, body: body)
        : await http.put(Uri.parse(url), headers: _headers, body: body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("فشل حفظ بيانات الشركة في السيرفر");
    }
  }

  // جلب الأدوية التابعة لشركة محددة
  static Future<List<dynamic>> getDrugsByCompany(int companyId) async {
    final response = await http
        .get(Uri.parse("$baseUrl/drugs/active/$companyId"), headers: _headers);
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("فشل جلب قائمة أدوية الشركة المستهدفة");
  }

  // إضافة دواء جديد للمستودع
  static Future<void> addDrug(Map<String, dynamic> drugData) async {
    final response = await http.post(Uri.parse("$baseUrl/drugs"),
        headers: _headers, body: jsonEncode(drugData));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("فشل إضافة الدواء الجديد للمخزون");
    }
  }

  // ==============================================================================
  // 2. قطاع الطلبات والفواتير اللحظية (Orders System)
  // ==============================================================================

  // إنشاء وإرسال طلب شراء أدوية جديد
  static Future<void> createRequest(
      {required int pharmacyId, required List<dynamic> items}) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/requests"),
            headers: _headers,
            body: jsonEncode({"pharmacy_id": pharmacyId, "items": items}),
          )
          .timeout(const Duration(
              seconds: 15)); // مهلة أطول لضمان وصول الفاتورة كاملة

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            jsonDecode(response.body)["error"] ?? "فشل إرسال الطلب");
      }
    } on TimeoutException {
      throw Exception("الاتصال ضعيف جداً، فشل وصول طلبك إلى خوادم المستودع");
    } catch (e) {
      throw Exception("خطأ غير متوقع في معالجة الفاتورة: $e");
    }
  }

  // جلب سجل الطلبات الخاص بصيدلية محددة
  static Future<List<dynamic>> getRequestsByPharmacy(int pharmacyId) async {
    final response = await http.get(
        Uri.parse("$baseUrl/requests?pharmacy_id=$pharmacyId"),
        headers: _headers);
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("خطأ في قراءة سجل الطلبات");
  }

  // تحديث حالة الطلب (قيد المعالجة، تم التجهيز، مرفوض) من لوحة التحكم
  static Future<void> updateRequestStatus(
      {required int requestId,
      required String status,
      List? itemsToUpdate,
      String? message}) async {
    final response = await http.put(
      Uri.parse("$baseUrl/requests/$requestId"),
      headers: _headers,
      body: jsonEncode({
        "status": status,
        "items_to_update": itemsToUpdate,
        "notification_message": message,
      }),
    );
    if (response.statusCode != 200)
      // ignore: curly_braces_in_flow_control_structures
      throw Exception("فشل تحديث حالة الطلب بالسيرفر");
  }

  // ==============================================================================
  // 3. المالية والإحصائيات الحركية (Finance & Stats)
  // ==============================================================================

  // جلب الإحصائيات العامة أو المخصصة لصيدلية معينة حسب الفترة الزمنية
  static Future<Map<String, dynamic>> getStatistics(String period,
      {int? pharmacyId}) async {
    try {
      String url = "$baseUrl/statistics?period=$period";
      if (pharmacyId != null) {
        url += "&pharmacy_id=$pharmacyId";
      }

      final response = await http.get(Uri.parse(url), headers: _headers);
      return response.statusCode == 200 ? jsonDecode(response.body) : {};
    } catch (e) {
      return {};
    }
  }

  // جلب كشوفات الأرصدة الكلية للصيدليات (للديسكتوب حصراً)
  static Future<List<dynamic>> getPharmaciesBalances() async {
    final response = await http.get(Uri.parse("$baseUrl/pharmacies-balances"),
        headers: _headers);
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  // جلب السجلات المالية والمقبوضات
  static Future<List<dynamic>> getPayments({int? pharmacyId}) async {
    final url = pharmacyId != null
        ? "$baseUrl/payments?pharmacy_id=$pharmacyId"
        : "$baseUrl/payments";
    final response = await http.get(Uri.parse(url), headers: _headers);
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("فشل جلب السجلات الماليّة الكلية");
  }

  // تحديث المبالغ والسندات المقبوضة
  static Future<bool> updatePaymentAmount(
      dynamic paymentId, double newAmount) async {
    try {
      final url = Uri.parse("$baseUrl/payments/$paymentId");

      final response = await http
          .put(
            url,
            headers:
                _headers, // 🔑 يمرر التوكن الجديد الموثق للأدمن تلقائياً ويمنع الـ 401
            body: jsonEncode({"amount_received": newAmount}),
          )
          .timeout(const Duration(seconds: 7));

      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print("🛑 خطأ كارثي منع تعديل السند المالي: $e");
      return false;
    }
  }
}
