// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  // ✨ التعديل الأول: إزالة late وجعله Nullable لمنع الشاشة الحمراء
  static IO.Socket? _socket;

  // جيتر (Getter) للوصول للسوكيت بأمان من أي مكان
  static IO.Socket get socket {
    if (_socket == null) {
      throw Exception("يجب استدعاء دالة connect أولاً قبل استخدام السوكيت");
    }
    return _socket!;
  }

  static void connect({
    required Function(dynamic) onNewRequest,
    required Function(dynamic) onOrderUpdated,
    required Function(dynamic) onOfferUpdated,
  }) {
    // 👈 إذا كان متصلاً بالفعل لا نكرر الاتصال
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      "http://localhost:3000",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      // ignore: avoid_print
      print("✅ تم الاتصال بنظام البث اللحظي بنجاح");
    });

    // ✨ الاستماع للأحداث (Events)
    _socket!.on("new_request", (data) => onNewRequest(data));
    _socket!.on("request_updated", (data) => onOrderUpdated(data));
    _socket!.on("offer_updated", (data) => onOfferUpdated(data));

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
