import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'services/notification_service.dart'; // استيراد خدمة الإشعارات والصوت
// ignore: unused_import
import 'services/socket_service.dart'; // استيراد محرك الربط اللحظي

// مكاتب الفايربيز السحابية
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  // التأكد من تهيئة أدوات فلاتر قبل تشغيل أي خدمة
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ تهيئة خدمات الفايربيز السحابية
  await Firebase.initializeApp();

  // 2️⃣ طلب الإذن الرسمي والمنبثق لظهور الإشعارات على شاشة الصيدلي
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // تهيئة محرك الإشعارات والصوت عند إقلاع التطبيق
  await NotificationService.init();

  // ✨ 3️⃣ استخراج وطباعة الـ Token الخاص بجهازك لنسخه
  String? token = await FirebaseMessaging.instance.getToken();
  // ignore: avoid_print
  print("🔑 FCM TOKEN: $token");

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
        primaryColor: const Color(0xFF007A87),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007A87),
          primary: const Color(0xFF007A87),
          secondary: const Color(0xFF10B981),
        ),
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontFamily: 'Cairo'),
        ),
      ),

      home: const LoginScreen(),
    );
  }
}
