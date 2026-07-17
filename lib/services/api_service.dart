import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart'; // 💡 استيراد كلاس الـ AuthService الخاص بالجوال

class ApiService {
  // ==============================================================================
  // ⚙️ الإعدادات الأساسية الخاصة بشبكة الجوال
  // ==============================================================================
// 💡 التعديل المطلوب لـ كروم: تحويل الرابط إلى localhost
  static const String baseUrl = 'http://192.168.43.68:5000/api';

  // 🛡️ [المحرك الأمني الحركي للجوال]:
  // يضمن قراءة التوكن حياً من الـ AuthService الخاص بالجوال عند كل طلب لمنع الـ 401
  static Map<String, String> get _headers {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (AuthService.token != null)
        "Authorization": "Bearer ${AuthService.token}",
    };
  }

  // ==============================================================================
  // 1. قطاع الشركات والأدوية (شاشة الصيدلي الرئيسية)
  // ==============================================================================

  // ✨ محرك الكاش الذكي (لعلاج بطء الإنترنت وسحب البضائع المخزنة محلياً بالجوال)
  static Future<List<dynamic>> getCompaniesWithDrugs() async {
    final prefs = await SharedPreferences.getInstance();
    const String cacheKey = "cached_companies_drugs";

    try {
      // محاولة جلب البيانات حية من مسار الجوال المطور بالتوافقية المرنة
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

  // جلب الشركات الصافي المخصص لشاشة الموبايل
  static Future<List<dynamic>> getCompanies() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/companies-with-drugs"), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // جلب الأدوية التابعة لشركة معينة والمتاحة للصيدلي
  static Future<List<dynamic>> getDrugsByCompany(int companyId) async {
    final response = await http
        .get(Uri.parse("$baseUrl/drugs/active/$companyId"), headers: _headers);
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("فشل جلب قائمة الأدوية من السيرفر");
  }

  // ==============================================================================
  // 2. قطاع السلة والطلبات (Orders System للصيدلي)
  // ==============================================================================

  // إنشاء وإرسال طلب شراء أدوية جديد من الجوال للمستودع
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
              seconds: 15)); // مهلة أطول لضمان وصول الفاتورة بالشبكات الضعيفة

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            jsonDecode(response.body)["error"] ?? "فشل إرسال الطلب");
      }
    } on TimeoutException {
      throw Exception("الإنترنت ضعيف جداً، فشل وصول طلبك إلى خوادم المستودع");
    } catch (e) {
      throw Exception("خطأ غير متوقع في معالجة الفاتورة: $e");
    }
  }

  // جلب سجل الفواتير والطلبات السابقة الخاصة بهذا الصيدلي فقط
  static Future<List<dynamic>> getRequestsByPharmacy(int pharmacyId) async {
    final response = await http.get(
        Uri.parse("$baseUrl/requests?pharmacy_id=$pharmacyId"),
        headers: _headers);
    return response.statusCode == 200
        ? jsonDecode(response.body)
        : throw Exception("خطأ في قراءة سجل الطلبات الحالية");
  }

  // ==============================================================================
  // 3. قطاع كشف الحساب المالي (الصيدلية حصراً)
  // ==============================================================================

  // جلب الإحصائيات والديون الخاصة بهذه الصيدلية فقط حسب الفترة الزمنية
  static Future<Map<String, dynamic>> getStatistics(String period,
      {required int pharmacyId}) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/statistics?period=$period&pharmacy_id=$pharmacyId"),
        headers: _headers,
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : {};
    } catch (e) {
      return {};
    }
  }

  // جلب كشف السندات والمقبوضات المالية والمدفوعات الخاصة بالصيدلية الحالية
  static Future<List<dynamic>> getPayments({required int pharmacyId}) async {
    try {
      final response = await http.get(
          Uri.parse("$baseUrl/payments?pharmacy_id=$pharmacyId"),
          headers: _headers);
      return response.statusCode == 200
          ? jsonDecode(response.body)
          : throw Exception("فشل جلب السجلات الماليّة الخاصة بصيدليتك");
    } catch (e) {
      throw Exception("خطأ شبكي أثناء معالجة البيانات المالية: $e");
    }
  }
} // 💡 نهاية كلاس الجوال الصافي والمستقل كلياً
