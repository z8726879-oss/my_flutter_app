import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // الرابط الأساسي للسيرفر (Android Emulator: 10.0.2.2 | Chrome: localhost)
  static const String baseUrl = 'http://127.0.0.1';

  // =============================================================
  // متغيرات الحالة (Static State)
  // يتم الوصول إليها من أي مكان في التطبيق (مثل ApiService)
  // =============================================================
  static String? token; // مفتاح الأمان JWT
  static Map<String, dynamic>? currentPharmacy; // بيانات الصيدلية الحالية

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
      final response = await http.post(
        Uri.parse("$baseUrl/pharmacy/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "pharmacy_name": pharmacyName,
          "phone": phone,
          "password": password,
          "city": city,
          "address": address,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data["error"] ?? "فشل إنشاء الحساب الصيدلاني");
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // =============================================================
  // 3. التحقق من تسجيل الدخول (Check Auth State)
  // =============================================================
  static bool get isLoggedIn => token != null;

  // =============================================================
  // 4. تسجيل الخروج والأمان (Logout)
  // =============================================================
  static void logout() {
    token = null;
    currentPharmacy = null;
    // يمكن هنا إضافة مسح الـ SharedPreferences إذا كنت تستخدمها
  }
}
