import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

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

    // 🌟 الإصدارات الحديثة تتطلب ضبط نظام darwin بدلاً من ios
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      darwin: DarwinInitializationSettings(),
    );

    // 🌟 دالة initialize الحديثة تتطلب معامل الاستجابة الإجباري لمنع الخطأ
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint("🚀 تم الضغط على الإشعار: ${details.payload}");
      },
    );

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

      // 🌟 تم تحديث تمرير إعدادات الـ iOS عبر صيغة الكود النصي المتوافقة مع تحديث audioplayers 6
      await _audioPlayer.setAudioContext(const AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.notification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: 'ambient',
        ),
      ));
      await _audioPlayer
          .play(AssetSource('sounds/notification-sound-for-whatsapp.mp3'));
    } catch (e) {
      debugPrint("🛑 خطأ في محرك الصوت البرمجي: ${e.toString()}");
    }
  }

  // 3. جلب الـ FCM Token وتحديثه في قاعدة البيانات
  static Future<void> registerDeviceToken(int pharmacyId) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      String? token;
      try {
        token = await messaging.getToken();
      } catch (firebaseError) {
        debugPrint("⚠️ خدمات جوجل بلاي غير مدعومة: $firebaseError");
      }
      if (token == null || token.isEmpty) {
        token = "device_token_pharma_id_${pharmacyId}_secure_2026";
      }
      final url = Uri.parse("http://192.168.43");
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"pharmacy_id": pharmacyId, "fcm_token": token}),
      );
    } catch (e) {
      debugPrint("❌ فشل تسجيل التوكن: $e");
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

    // 🌟 إضافة تفاصيل داروين الافتراضية لمنع انهيار البناء في النسخ الحديثة
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _localNotifications.show(0, title, body, details);
  }

  // 6️⃣ جلب الإشعارات المحفوظة من قاعدة بيانات السيرفر
  static Future<List<dynamic>> fetchSavedNotifications(int pharmacyId) async {
    try {
      final url = Uri.parse('http://192.168.43');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['notifications'];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
