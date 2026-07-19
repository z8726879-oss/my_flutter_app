import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  // الرابط الأساسي للسيرفر (Android Emulator: 10.0.2.2 | Chrome: localhost)
  static const String baseUrl = 'http://192.168.43.68:5000/api';

  // =============================================================
  // متغيرات الحالة (Static State)
  // يتم الوصول إليها من أي مكان في التطبيق (مثل ApiService)
  // =============================================================
  static String? token; // مفتاح الأمان JWT
  static Map<String, dynamic>? currentPharmacy; // بيانات الصيدلية الحالية

  // 💡 [الحصن التلقائي]: محرك الهيدرز الذكي الذي يقرأ التوكن حياً ويغذي ملف ApiService
  static Map<String, String> get headers {
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // =============================================================
  // 1. تسجيل الدخول (Login)
  // =============================================================
  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/pharmacy/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✨ حفظ التوكن وبيانات الصيدلية فور النجاح
        token = data["token"];
        currentPharmacy = data["pharmacy"];
        return data;
      } else {
        // رمي رسالة الخطأ القادمة من السيرفر (مثل: كلمة المرور خطأ)
        throw Exception(data["error"] ?? "فشل تسجيل الدخول");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // =============================================================
  // 2. إنشاء حساب جديد (Register)
  // =============================================================
  static Future<Map<String, dynamic>> register({
    required String pharmacyName,
    required String phone,
    required String password,
    required String city,
    required String address,
  }) async {
    try {
      // 👈 2. جلب المفتاح السري تلقائياً من الملف الخارجي (.env)
      final String secretKey = dotenv.env['PHARMA_SECURE_KEY'] ?? '';

      final response = await http.post(
        Uri.parse("$baseUrl/pharmacy/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "pharmacy_name": pharmacyName,
          "phone": phone,
          "password": password,
          "city": city,
          "address": address,
          "security_key":
              secretKey, // 👈 3. حقن المفتاح السري هنا تلقائياً ليمر من جدار حماية السيرفر
        }),
      );

      final data = jsonDecode(response.body);

      // هنا قمنا بتعديل قراءة الخطأ ليتوافق مع السيرفر (لأن السيرفر الخاص بك يرجع الحقل باسم message وليس error)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data["message"] ?? "فشل إنشاء الحساب الصيدلاني");
      }
    } catch (e) {
      // تنظيف رسالة الخطأ من كلمة Exception الزائدة لتظهر نظيفة للمستخدم في الـ UI
      String errorMsg = e.toString();
      if (errorMsg.startsWith("Exception: ")) {
        errorMsg = errorMsg.replaceFirst("Exception: ", "");
      }
      throw Exception(errorMsg);
    }
  }

  // =============================================================
  // 3. التحقق من تسجيل الدخول (Check Auth State)
  // =============================================================
  static bool get isLoggedIn =>
      token !=
      null; // =============================================================
  // 4. تسجيل الخروج والأمان (Logout)
  // =============================================================
  static void logout() {
    token = null;
    currentPharmacy = null;
  }
}
