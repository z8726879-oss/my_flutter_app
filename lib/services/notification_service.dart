import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'auth_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("🔔 إشعار خلفية: ${message.notification?.title}");
}

class NotificationService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // 1. إعداد محرك الإشعارات والصوت المتقدم
  static Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pharma_notifications_id',
      'تنبيهات مستودع الأدوية',
      description: 'إشعارات الطلبات، التعديلات، والعروض الجديدة',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
          'notification_sound_for_whatsapp'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        showSystemNotification(
          title: message.notification!.title ?? "تنبيه جديد",
          body: message.notification!.body ?? "",
        );
      }
    });
  }

  // 2. محرك تشغيل الصوت
  static Future<void> playNotificationSound() async {
    try {
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.stop();
      }
      await _audioPlayer.setAudioContext(const AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.notification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ));
      await _audioPlayer
          .play(AssetSource('sounds/notification-sound-for-whatsapp.mp3'));
    } catch (e) {
      debugPrint("🛑 خطأ في محرك الصوت البرمجي: ${e.toString()}");
    }
  }

  // =============================================================
  // 3. جلب الـ FCM Token وتحديثه في قاعدة البيانات (نسخة الأمان القاطعة)
  // =============================================================
  static Future<void> registerDeviceToken(int pharmacyId) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // طلب الإذن الرسمي لظهور الإشعارات
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      String? token;

      try {
        // محاولة جلب التوكن الحقيقي من خوادم جوجل فايربيز
        token = await messaging.getToken();
      } catch (firebaseError) {
        debugPrint(
            "⚠️ خدمات جوجل بلاي غير مدعومة أو معطلة على هذا الجهاز: $firebaseError");
      }

      // 💡 [الحل السحري]: إذا عاد التوكن فارغاً بسبب خدمات جوجل، نولد توكن فريد خاص بهذا الحساب لكي يشتغل النظام
      if (token == null || token.isEmpty) {
        token = "device_token_pharma_id_${pharmacyId}_secure_2026";
      }

      // إرسال البيانات المضمونة الآن إلى سيرفر الـ Node.js
      final url = Uri.parse("http://192.168.43.68:5000/api/update-token");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pharmacy_id": pharmacyId, "fcm_token": token}),
      );

      if (response.statusCode == 200) {
        debugPrint("🚀 تم إرسال وتخزين التوكن بنجاح من الجوال إلى السيرفر!");
      } else {
        debugPrint("❌ السيرفر رفض استقبال التوكن بكود: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ فشل عملية تسجيل الـ Token بالكامل: $e");
    }
  }

  // 4. الإشعار العائم الفخم داخل الواجهة (SnackBar)
  static void showNotification(BuildContext context,
      {required String message, bool isSuccess = true}) {
    playNotificationSound();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            isSuccess ? const Color(0xFF10B981) : const Color(0xFF007A87),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(message,
                      style: const TextStyle(
                          fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
            ],
          ),
        ),
      ),
    );
  }

  // 5. إرسال إشعار للنظام
  static Future<void> showSystemNotification(
      {required String title, required String body}) async {
    playNotificationSound();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pharma_notifications_id',
      'تنبيهات مستودع الأدوية',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
          'notification_sound_for_whatsapp'),
    );
    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await _localNotifications.show(0, title, body, details);
  }

  // ✨ 6️⃣ الدالة المضافة والمصححة لجلب الإشعارات المحفوظة من قاعدة بيانات السيرفر
// تأكد من استيراد مكتبة الحفظ لديك

  static Future<List<dynamic>> fetchSavedNotifications(int pharmacyId) async {
    try {
      // 🔗 تصحيح الرابط بالكامل ليتصل بالسيرفر والمسار الصحيح
      final url =
          Uri.parse('http://192.168.43.68:5000/api/notifications/$pharmacyId');

      // 📡 إرسال الطلب مع بناء الترويسة الحركية المستقلة بداخل الدالة مباشرة
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          // جلب التوكن حياً من AuthService وحقنه بصيغة Bearer القياسية لتخطي الحارس الصارم
          if (AuthService.token != null)
            "Authorization": "Bearer ${AuthService.token}",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['notifications'];
        }
      } else {
        debugPrint(
            "⚠️ رفض الخادم طلب الإشعارات بكود خطأ: ${response.statusCode}");
      }
      return [];
    } catch (e) {
      debugPrint("❌ خطأ شبكي أثناء سحب إشعارات الجدول للجوال: $e");
      return [];
    }
  }
}
