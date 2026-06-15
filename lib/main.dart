import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'services/notification_service.dart'; // استيراد خدمة الإشعارات والصوت
// ignore: unused_import
import 'services/socket_service.dart'; // استيراد محرك الربط اللحظي

void main() async {
  // التأكد من تهيئة أدوات فلاتر قبل تشغيل أي خدمة
  WidgetsFlutterBinding.ensureInitialized();

  // ✨ تهيئة محرك الإشعارات والصوت عند إقلاع التطبيق (مواصفات عالمية)
  await NotificationService.init();

  runApp(const PharmacyMobileApp());
}

class PharmacyMobileApp extends StatelessWidget {
  const PharmacyMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "نظام مستودع الأدوية الذكي - الصيادلة",

      // ==========================================
      // الهوية البصرية والطبية الموحدة (Theme)
      // ==========================================
      theme: ThemeData(
        useMaterial3: true,
        // تخصيص الألوان الطبية المعتمدة في مشروعك الفخم
        primaryColor: const Color(0xFF007A87),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007A87),
          primary: const Color(0xFF007A87),
          secondary: const Color(0xFF10B981), // الأخضر للنجاح والعروض
        ),
        // استخدام خط كايرو (تأكد من تعريفه في pubspec.yaml)
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),

        // تحسين مظهر النصوص بشكل عام
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontFamily: 'Cairo'),
        ),
      ),

      // نقطة الانطلاق: شاشة تسجيل الدخول لحماية البيانات
      home: const LoginScreen(),
    );
  }
}
