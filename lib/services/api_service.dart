import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart'; // 💡 استيراد كلاس الـ AuthService الخاص بالجوال
import 'package:flutter/foundation.dart';

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
      debugPrint(
          "ℹ️ [رادار الحماية]: السيرفر غير متاح، تم تفعيل خطة الطوارئ وجلب كاش الشركات");
      return jsonDecode(cachedData);
    }

    // 🔒 إذا كان الإنترنت مقطوعاً في أول مرة يفتح فيها التطبيق (لا يوجد كاش قديم)
    throw Exception(
        "❌ عذراً، فشل الاتصال بخادم المستودع ولا توجد بيانات مسجلة مسبقاً. يرجى التحقق من الإنترنت.");
  }

  // جلب الشركات الصافي المخصص لشاشة الموبايل - أمان كامل وإرشاد للمستخدم
  static Future<List<dynamic>> getCompanies() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/companies-with-drugs"), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // إذا كان السيرفر يعمل ولكنه أعاد كود خطأ (مثلاً 500 أو 404)، نعود بمصفوفة فارغة لحماية الواجهة
        return [];
      }
    } catch (e) {
      // 🔬 للمطور فقط: تظهر في الـ Terminal عندك لغرض الصيانة والمراقبة الفنية
      debugPrint('🚨 [رادار الشركات الداخلي] فشل الاتصال بالسيرفر: $e');

      // 🔒 للمستخدم النهائي (الصيدلي): رمي رسالة معقمة تحجب الـ IP وتوضح سبب المشكلة
      throw Exception(
          "❌ عذراً، فشل الاتصال بخادم المستودع. يرجى التحقق من اتصال الإنترنت لديك وإعادة المحاولة.");
    }
  }

  // جلب قائمة الأدوية النشطة التابعة لشركة محددة بأمان سيبراني كامل
  static Future<List<dynamic>> getDrugsByCompany(int companyId) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/drugs/active/$companyId"), headers: _headers)
          .timeout(const Duration(
              seconds:
                  10)); // ⏳ مهلة 10 ثوانٍ لمنع تعليق واجهة التطبيق في حال ضعف إنترنت الصيدلية

      return response.statusCode == 200
          ? jsonDecode(response.body)
          : throw Exception("فشل جلب قائمة الأدوية من السيرفر");
    } catch (e) {
      // 🔬 للمطور فقط: يطبع المسار والـ IP الحقيقي المتضرر داخل الـ VS Code عندك فقط لغرض الصيانة
      debugPrint(
          '🚨 [رادار الأدوية الداخلي] عطل في جلب أصناف الشركة رقم $companyId للسبب: $e');

      // 🔒 للمستخدم النهائي (الصيدلي): رسالة عامة ومعقمة تحجب الـ IP والمنفذ تماماً
      throw Exception(
          "❌ عذراً، فشل الاتصال الآمن بخادم المستودع. يرجى التحقق من جودة الإنترنت لديك وإعادة المحاولة.");
    }
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
      // 🔬 للمطور فقط: تطبع الخطأ الحقيقي والـ IP في الـ VS Code عندك فقط ولا يراها الصيدلي
      debugPrint("🚨 [تقرير الصيانة الداخلي]: الخطأ الشبكي الفعلي هو: $e");

      // 🔒 للمستخدم النهائي (الصيدلي): رسالة عامة، معقمة، ومحمية سيبرانياً 100%
      throw Exception(
          "❌ عذراً، فشل الاتصال الآمن بخادم المستودع. يرجى التحقق من جودة الإنترنت لديك وإعادة المحاولة.");
    }
  }

  // جلب سجل الفواتير والطلبات السابقة الخاصة بهذا الصيدلي فقط
  static Future<List<dynamic>> getRequestsByPharmacy(int pharmacyId) async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/requests?pharmacy_id=$pharmacyId"),
              headers: _headers)
          .timeout(const Duration(
              seconds: 10)); // مهلة 10 ثوانٍ لمنع تعليق واجهة التطبيق

      return response.statusCode == 200
          ? jsonDecode(response.body)
          : throw Exception("خطأ في قراءة سجل الطلبات الحالية");
    } catch (e) {
      // 🔬 للمطور فقط: تطبع الخطأ الحقيقي والـ IP في الـ VS Code عندك لغرض الصيانة
      debugPrint('🚨 [رادار الفواتير الداخلي] عطل في الشبكة أو السيرفر: $e');

      // 🔒 للمستخدم النهائي (الصيدلي): رسالة معقمة ومحمية سيبرانياً تحجب الـ IP تماماً
      throw Exception(
          "❌ عذراً، فشل الاتصال الآمن بخادم المستودع. يرجى التحقق من جودة الإنترنت لديك وإعادة المحاولة لاحقاً.");
    }
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
      // 🔬 للمطور فقط: تطبع الخطأ الحقيقي والـ IP في الـ VS Code عندك فقط ولا يراها الصيدلي
      debugPrint("🚨 [تقرير الصيانة الداخلي]: الخطأ الشبكي الفعلي هو: $e");

      // 🔒 للمستخدم النهائي (الصيدلي): رسالة عامة، معقمة، ومحمية سيبرانياً 100%
      throw Exception(
          "❌ عذراً، فشل الاتصال الآمن بخادم المستودع. يرجى التحقق من جودة الإنترنت لديك وإعادة المحاولة.");
    }
  } // جلب كشف السندات والمقبوضات المالية والمدفوعات الخاصة بالصيدلية الحالية

  static Future<List<dynamic>> getPayments({required int pharmacyId}) async {
    try {
      final response = await http.get(
          Uri.parse("$baseUrl/payments?pharmacy_id=$pharmacyId"),
          headers: _headers);
      return response.statusCode == 200
          ? jsonDecode(response.body)
          : throw Exception("فشل جلب السجلات الماليّة الخاصة بصيدليتك");
    } catch (e) {
      // 🔬 للمطور فقط: تطبع الخطأ الحقيقي والـ IP في الـ VS Code عندك فقط ولا يراها الصيدلي
      debugPrint("🚨 [تقرير الصيانة الداخلي]: الخطأ الشبكي الفعلي هو: $e");

      // 🔒 للمستخدم النهائي (الصيدلي): رسالة عامة، معقمة، ومحمية سيبرانياً 100%
      throw Exception(
          "❌ عذراً، فشل الاتصال الآمن بخادم المستودع. يرجى التحقق من جودة الإنترنت لديك وإعادة المحاولة.");
    }
  }
} // 💡 نهاية كلاس الجوال الصافي والمستقل كلياً
