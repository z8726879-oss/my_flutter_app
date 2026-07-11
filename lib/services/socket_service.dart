// ignore_for_file: library_prefixes
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;

  static IO.Socket get socket {
    if (_socket == null) {
      throw Exception("أولاً قبل استخدام السوكيت يجب استدعاء دالة connect");
    }
    return _socket!;
  }

  // 💡 التعديل الجوهري: استقبال التوكن الرقمي للصيدلي لتجاوز حارس أمان السيرفر الجديد
  static void connect(
      String userToken, Function(dynamic) onNotificationReceived) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      "http://192.168.43.68:5000", // 💡 تم حذف /api لنجاح المزامنة مع السيرفر القياسي
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          // 💡 الحصن القياسي: حقن التوكن الرقمي لتأمين وتوثيق هوية هاتف الصيدلي تلقائياً
          .setAuth({'token': 'Bearer $userToken'})
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint("✅ تم الاتصال الموثق بنظام البث اللحظي للجوال الصيدلية بنجاح");
    });

    _socket!.onDisconnect((_) {
      debugPrint("❌ انقطع الاتصال بالسيرفر السحابي للمستودع");
    });

    _socket!.onConnectError((err) {
      debugPrint("🛑 فشل توثيق اتصال الجوال بالسوكيت: $err");
    });

    // 💡 الاستماع لحدث الإشعارات القياسي المفرز داخل الغرفة المحمية للصيدلي عمر
    _socket!.on("notification", (data) => onNotificationReceived(data));
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
