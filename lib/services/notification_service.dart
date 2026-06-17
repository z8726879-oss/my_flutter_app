import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

// معالج الخلفية لـ Firebase
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("🔔 إشعار خلفية: ${message.notification?.title}");
}

class NotificationService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // =============================================================
  // 1. إعداد محرك الإشعارات والصوت المتقدم (تُستدعى في main.dart)
  // =============================================================
  static Future<void> init() async {
    // إعدادات أيقونة الإشعارات الافتراضية لأندرويد
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(initSettings);

    // 🔊 المحرك البرمجي لربط نظام الصوت بقناة أندرويد الرسمية (Android Channel Audio Engine)
    // نحدد ملف التنبيه بدون الامتداد لتتعرف عليه الـ SDK محلياً كـ Raw Resource إذا لزم الأمر
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pharma_notifications_id',
      'تنبيهات مستودع الأدوية',
      description: 'إشعارات الطلبات، التعديلات، والعروض الجديدة',
      importance: Importance.max,
      playSound: true,
      // ربط القناة بملف الصوت بالنظام المكتبي الداخلي للأندرويد
      sound: RawResourceAndroidNotificationSound(
          'notification_sound_for_whatsapp'),
    );

    // تسجيل القناة داخل نظام تشغيل أندرويد لفرض تشغيل الصوت المخصص
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // تفعيل لقط إشعارات Firebase
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

  // =============================================================
  // 2. محرك تشغيل الصوت (متوافق مع أحدث إصدارات audioplayers 5.x)
  // =============================================================
  static Future<void> playNotificationSound() async {
    try {
      // إيقاف المحرك البرمجي للصوت إذا كان مشغولاً لإعادة تشغيله فوراً (Anti-overlapping)
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.stop();
      }

      // ضبط خصائص الصوت برمجياً (Audio Context) ليعامل كصوت تنبيه ونغمة رنين وليس موسيقى
      await _audioPlayer.setAudioContext(const AudioContext(
        android: AudioContextAndroid(
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.notification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
        ),
      ));

      // تشغيل ملف الصوت المخصص من مجلد الـ assets
      await _audioPlayer.play(
        AssetSource('sounds/notification-sound-for-whatsapp.mp3'),
      );
    } catch (e) {
      debugPrint("🛑 خطأ في محرك الصوت البرمجي: ${e.toString()}");
    }
  }

  // =============================================================
  // 3. جلب الـ FCM Token وتحديثه في قاعدة البيانات
  // =============================================================
  static Future<void> registerDeviceToken(int pharmacyId) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      String? token = await messaging.getToken();

      if (token != null) {
        final url = Uri.parse("http://192.168.43.68:5000/api");
        await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"pharmacy_id": pharmacyId, "fcm_token": token}),
        );
      }
    } catch (e) {
      debugPrint("❌ فشل تسجيل الـ Token: $e");
    }
  }

  // =============================================================
  // 4. الإشعار العائم الفخم داخل الواجهة (SnackBar)
  // =============================================================
  static void showNotification(BuildContext context,
      {required String message, bool isSuccess = true}) {
    playNotificationSound(); // تشغيل صوت المحرك تلقائياً

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

  // =============================================================
  // 5. إرسال إشعار للنظام (يظهر في ستارة الإشعارات العلوية للهاتف)
  // =============================================================
  static Future<void> showSystemNotification(
      {required String title, required String body}) async {
    // تشغيل المحرك الديناميكي للصوت فوراً
    playNotificationSound();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pharma_notifications_id',
      'تنبيهات مستودع الأدوية',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      // تمرير نغمة الصوت لتتعرف عليها ستارة الإشعارات عند إغلاق التطبيق
      sound: RawResourceAndroidNotificationSound(
          'notification_sound_for_whatsapp'),
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await _localNotifications.show(0, title, body, details);
  }
}
