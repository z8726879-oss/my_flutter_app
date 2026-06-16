import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ApiService {
  // =============================================================
  // الإعدادات الأساسية (Base Config)
  // قم بتغيير localhost إلى IP السيرفر الحقيقي عند الرفع
  // =============================================================
  static const String baseUrl = 'http://127.0.0.1';

  // ✨ المحرك الأمني: إرفاق التوكن تلقائياً في هيدرز كل طلب
  static Map<String, String> get _headers {
    final Map<String, String> headers = {
      "Content-Type": "application/json",
      "Accept": "application/json",
    };
    if (AuthService.token != null) {
      headers["Authorization"] = "Bearer ${AuthService.token}";
    }
    return headers;
  }

  // =============================================================
  // ✨ محرك الكاش الذكي (لعلاج بطء الإنترنت في سوريا)
  // =============================================================
  static Future<List<dynamic>> getCompaniesWithDrugs() async {
    final prefs = await SharedPreferences.getInstance();
    const String cacheKey = "cached_companies_drugs";

    try {
      // محاولة الجلب مع مهلة زمنية قصيرة (10 ثواني) لعدم إزعاج المستخدم
      final response = await http
          .get(Uri.parse("$baseUrl/companies-with-drugs"), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await prefs.setString(cacheKey, response.body);
        return jsonDecode(response.body);
      }
    } catch (e) {
      // ignore: avoid_print
      print("⚠️ نت ضعيف أو مقطوع، يتم استخدام النسخة المخزنة محلياً");
    }

    // قراءة البيانات من ذاكرة الجوال في حال فشل الاتصال
    String? cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      return jsonDecode(cachedData);
    }
    return [];
  }

  // =============================================================
  // 1. قطاع الشركات والأدوية (Inventory)
  // =============================================================

  static Future<List<dynamic>> getCompanies() async {
    try {
      final response =
          await http.get(Uri.parse("$baseUrl/companies"), headers: _headers);
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> addOrUpdateCompany(
      {int? id, required String name, required String image}) async {
    final url = id == null ? "$baseUrl/companies" : "$baseUrl/companies/$id";
    final body = jsonEncode({"name": name, "image": image});
    final response = id == null
        ? await http.post(Uri.parse(url), headers: _headers, body: body)
        : await http.put(Uri.parse(url), headers: _headers, body: body);
    if (response.statusCode != 200 && response.statusCode != 201)
      // ignore: curly_braces_in_flow_control_structures
      throw Exception("فشل الحفظ");
  }

  static Future<List<dynamic>> getDrugsByCompany(int companyId) async {
    final response = await http
        .get(Uri.parse("$baseUrl/drugs/active/$companyId"), headers: _headers);
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("فشل جلب الأدوية");
  }

  static Future<void> addDrug(Map<String, dynamic> drugData) async {
    final response = await http.post(Uri.parse("$baseUrl/drugs"),
        headers: _headers, body: jsonEncode(drugData));
    if (response.statusCode != 200 && response.statusCode != 201)
      // ignore: curly_braces_in_flow_control_structures
      throw Exception("فشل إضافة الدواء");
  }

  // =============================================================
  // 2. قطاع الطلبات (Orders System)
  // =============================================================

  static Future<void> createRequest(
      {required int pharmacyId, required List<dynamic> items}) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/requests"),
            headers: _headers,
            body: jsonEncode({"pharmacy_id": pharmacyId, "items": items}),
          )
          .timeout(
              const Duration(seconds: 15)); // مهلة أطول للطلبات لضمان الوصول

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(jsonDecode(response.body)["error"] ?? "فشل الإرسال");
      }
    } on TimeoutException {
      throw Exception("الإنترنت ضعيف جداً، فشل إرسال الطلب للسيرفر");
    } catch (e) {
      throw Exception("خطأ غير متوقع: $e");
    }
  }

  static Future<List<dynamic>> getRequestsByPharmacy(int pharmacyId) async {
    final response = await http.get(
        Uri.parse("$baseUrl/requests?pharmacy_id=$pharmacyId"),
        headers: _headers);
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("خطأ في السجل");
  }

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
    if (response.statusCode != 200) throw Exception("فشل التحديث");
  }

  // =============================================================
  // 3. المالية والإحصائيات (Finance & Stats)
  // =============================================================

  static Future<Map<String, dynamic>> getStatistics(String period) async {
    try {
      final response = await http.get(
          Uri.parse("$baseUrl/statistics?period=$period"),
          headers: _headers);
      return response.statusCode == 200 ? jsonDecode(response.body) : {};
    } catch (e) {
      return {};
    }
  }

  static Future<List<dynamic>> getPharmaciesBalances() async {
    final response = await http.get(Uri.parse("$baseUrl/pharmacies-balances"),
        headers: _headers);
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  static Future<List<dynamic>> getPayments({int? pharmacyId}) async {
    final url = pharmacyId != null
        ? "$baseUrl/payments?pharmacy_id=$pharmacyId"
        : "$baseUrl/payments";
    final response = await http.get(Uri.parse(url), headers: _headers);
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("فشل جلب المالية");
  }
}
