import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // مكتبة مهمة لتمكين ميزة النسخ للحافظة
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
  runApp(const PharmacyMobileApp());
}

class PharmacyMobileApp extends StatelessWidget {
  const PharmacyMobileApp({super.key});

  // ✨ دالة سحرية لعرض الرمز على الشاشة بمجرد فتح التطبيق ودخول شاشة اللوجن
  void _showTokenDialog(BuildContext context) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        // ننتظر ثانية واحدة حتى تكتمل واجهة الشاشة تماماً ثم نظهر النافذة
        Future.delayed(const Duration(seconds: 1), () {
          if (!context.mounted) return;
          showDialog(
            context: context,
            barrierDismissible:
                false, // لا تختفي النافذة إلا عند الضغط على زر الإغلاق
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: const Text(
                  "🔑 الرمز الخاص بجهازك (FCM Token)",
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                content: SingleChildScrollView(
                  child: SelectableText(
                    token,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.blueGrey),
                    textAlign: TextAlign.center,
                  ),
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: token));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("تم نسخ الرمز بنجاح! ✅"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text("نسخ الرمز",
                        style: TextStyle(fontFamily: 'Cairo')),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007A87),
                        foregroundColor: Colors.white),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text("إغلاق",
                        style:
                            TextStyle(fontFamily: 'Cairo', color: Colors.red)),
                  ),
                ],
              );
            },
          );
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print("⚠️ فشل جلب الرمز: $e");
    }
  }

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
      // ✨ استدعاء الدالة السحرية فور تحميل شاشة تسجيل الدخول
      home: Builder(
        builder: (context) {
          _showTokenDialog(context);
          return const LoginScreen();
        },
      ),
    );
  }
}
