import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // تعريف المحركات كـ static لضمان العمل في كامل التطبيق
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // =============================================================
  // 1. إعداد الإشعارات (تُستدعى مرة واحدة في main.dart)
  // =============================================================
  static Future<void> init() async {
    // إعداد أيقونة الإشعارات للأندرويد
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(initSettings);

    // إنشاء قناة تنبيه للأندرويد (ضروري لعمل الصوت في النسخ الحديثة)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'pharma_notifications_id',
      'تنبيهات مستودع الأدوية',
      description: 'إشعارات الطلبات، التعديلات، والعروض الجديدة',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // =============================================================
  // 2. محرك تشغيل الصوت (متوافق مع أحدث إصدارات audioplayers)
  // =============================================================
  static Future<void> playNotificationSound() async {
    try {
      // إيقاف أي صوت سابق لمنع التداخل
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.stop();
      }

      // تشغيل ملف الصوت الخاص بك من الـ Assets
      await _audioPlayer.play(
        AssetSource('sounds/notification-sound-for-whatsapp.mp3'),
      );
    } catch (e) {
      debugPrint("🛑 خطأ في محرك الصوت: ${e.toString()}");
    }
  }

  // =============================================================
  // 3. الإشعار العائم الفخم (Internal UI SnackBar)
  // =============================================================
  static void showNotification(
    BuildContext context, {
    required String message,
    bool isSuccess = true,
  }) {
    // تشغيل الصوت تلقائياً مع ظهور الإشعار
    playNotificationSound();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            isSuccess ? const Color(0xFF10B981) : const Color(0xFF007A87),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 4),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              const Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // 4. إرسال إشعار للنظام (يظهر في ستارة الإشعارات العلوية)
  // =============================================================
  static Future<void> showSystemNotification(
      {required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'pharma_notifications_id',
      'تنبيهات مستودع الأدوية',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);
    await _localNotifications.show(0, title, body, details);
  }
}
