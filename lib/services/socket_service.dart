// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static IO.Socket? _socket;

  static IO.Socket get socket {
    if (_socket == null) {
      throw Exception("أولاً قبل استخدام السوكيت يجب استدعاء دالة connect");
    }
    return _socket!;
  }

  static void connect(String pharmacyId) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      "http://192.168.43.68:5000/api",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      // ignore: avoid_print
      print("✅ تم الاتصال بنظام البث اللحظي بنجاح للشركة والصيدلية");
    });

    _socket!.on("notification_$pharmacyId", (data) {
      // ignore: avoid_print
      print("🔔 إشعار جديد مستلم في الخلفية: ${data['message']}");
    });

    // ignore: avoid_print
    _socket!.onDisconnect((_) => print("❌ انقطع الاتصال بالسيرفر"));
    // ignore: avoid_print
    _socket!.onError((err) => print("⚠️ خطأ في السوكيت: $err"));
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
