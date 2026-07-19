import 'dart:io'; // 🌟 تم إضافة هذه المكتبة للتحقق من نظام التشغيل بأمان
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // مكتبة مهمة لتمكين ميزة النسخ للحافظة
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 👈 1. تم استيراد حزمة المفاتيح السرية هنا بأمان
import 'login_screen.dart';
import 'services/notification_service.dart'; // استيراد خدمة الإشعارات والصوت
// ignore: unused_import
import 'services/socket_service.dart'; // استيراد محرك الربط اللحظي
// مكاتب الفايربيز السحابية
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/auth_service.dart'; // 💡 تأكد من استيراد كلاس الـ Auth لجلب معرف الصيدلية

void main() async {
  // التأكد من تهيئة أدوات فلاتر قبل تشغيل أي خدمة
  WidgetsFlutterBinding.ensureInitialized();

  // 👈 2. تم إضافة سطر تحميل ملف السر هنا ليتم قراءته فور تشغيل التطبيق
  await dotenv.load(fileName: ".env");

  // 🌟 [تعديل الحماية للـ iOS]: تشغيل خدمات Firebase فقط إذا كان النظام أندرويد
  if (Platform.isAndroid) {
    // 1️⃣ تهيئة خدمات الفايربيز السحابية
    await Firebase.initializeApp();

    // 2️⃣ طلب الإذن الرسمي والمنبثق لظهور الإشعارات على شاشة الصيدلي
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 💡 [التعديل المضاف هنا]: الاستماع لتغير الرمز تلقائياً في الخلفية وإرساله للسيرفر فوراً
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final pharmacyId = AuthService.currentPharmacy?['id'];
      if (pharmacyId != null) {
        int realId = int.tryParse(pharmacyId.toString()) ?? 0;
        if (realId != 0) {
          // استدعاء دالة الإرسال للسيرفر لتحديث قاعدة البيانات بالرمز الجديد
          await NotificationService.registerDeviceToken(realId);
          debugPrint(
              "🔄 تم اكتشاف تغير الرمز وتحديثه تلقائياً في السيرفر: $newToken");
        }
      }
    });

    // تهيئة محرك الإشعارات والصوت عند إقلاع التطبيق
    await NotificationService.init();
  } else {
    // في حال كان آيفون، يتم طباعة رسالة في الكونسول وتخطي التثبيت بسلام لحل خطأ البناء
    debugPrint("ℹ️ Firebase Cloud Messaging is disabled on iOS platform.");
  }

  runApp(const PharmacyMobileApp());
}

class PharmacyMobileApp extends StatelessWidget {
  const PharmacyMobileApp({super.key});

  // ✅ تم حذف الدالة السحرية _showTokenDialog بالكامل لمنع ظهور نافذة نسخ الرمز

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "نظام مستودع الأدوية الذكي - الصيادلة",
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
      // ✨ تم تنظيف الـ home وتوجيهه مباشرة إلى شاشة تسجيل الدخول دون نوافذ منبثقة
      home: const LoginScreen(),
    );
  }
}
