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

  static void connect(
      String userToken, Function(dynamic) onNotificationReceived) {
    if (_socket != null && _socket!.connected) {
      // 🔒 حماية إضافية: إذا كان السوكيت متصلاً بالفعل، نظف الاستماع القديم وافتح الجديد فقط لمنع التراكم
      _socket!.off("notification");
      _socket!.on("notification", (data) => onNotificationReceived(data));
      return;
    }

    _socket = IO.io(
      "http://192.168.43.68:5000",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
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

    // 🔒 جدار الحماية من تسريب الذاكرة: تنظيف وإلغاء أي استماع ميت قديم في الرام قبل تفعيل الجديد
    _socket!.off("notification");
    _socket!.on("notification", (data) => onNotificationReceived(data));
  }

  static void disconnect() {
    // 🔒 تنظيف وتدمير الأحداث من الرام تماماً عند قطع الاتصال
    _socket?.off("notification");
    _socket?.disconnect();
    _socket = null;
  }
}
