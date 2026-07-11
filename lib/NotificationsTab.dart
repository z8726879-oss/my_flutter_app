// ignore_for_file: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/socket_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

class PharmacyNotificationsTab extends StatefulWidget {
  const PharmacyNotificationsTab({super.key});

  @override
  State<PharmacyNotificationsTab> createState() =>
      _PharmacyNotificationsTabState();
}

class _PharmacyNotificationsTabState extends State<PharmacyNotificationsTab> {
  bool isLoading = true;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    _loadStoredNotifications(); // 1. جلب الإشعارات من قاعدة بيانات السيرفر ومن الهاتف
    setupSocketListener(); // 2. ربط السوكيت الفوري
  }

  // ==============================================================================
  // [النسخة المحصنة والمزامنة تماماً] الدمج وتصفير الكاش التلقائي مع السيرفر
  // ==============================================================================
  Future<void> _loadStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    // أ. أولاً: نقرأ الإشعارات القديمة المحفوظة في الهاتف لعرضها فوراً دون انتظار الشبكة
    final String? storedData = prefs.getString('saved_notifications');
    if (storedData != null && mounted) {
      setState(() {
        notifications = List<Map<String, dynamic>>.from(jsonDecode(storedData));
        isLoading = false;
      });
    }

    // ب. ثانياً: المزامنة الصارمة والتحديث من قاعدة بيانات السيرفر
    final pharmacyId = AuthService.currentPharmacy?['id'];
    if (pharmacyId != null) {
      try {
        final List<dynamic> serverNotifications =
            await NotificationService.fetchSavedNotifications(pharmacyId);

        // 💡 التعديل الجوهري والأخير: تمت إزالة شرط الاستثناء لضمان مسح وتصفير كاش الهاتف
        // فور قيام السيرفر بتنظيف الإشعارات القديمة فجراً لتتطابق الواجهات تماماً
        if (mounted) {
          setState(() {
            notifications = serverNotifications.map((item) {
              return {
                "title": item['title'] ?? "تنبيه جديد 🔔",
                "body": item['message'] ?? "",
                "time": "الآن",
                "is_read": true
              };
            }).toList();
            isLoading = false;
          });

          // تحديث وتطهير الكاش الداخلي للهاتف فوراً بالبيانات الحية المتبقية بالسيرفر فقط
          _saveNotificationsToStorage();
        }
      } catch (e) {
        debugPrint(
            "⚠️ فشل تحديث البيانات من السيرفر، تم الاعتماد على كاش الهاتف: $e");
      }
    }

    if (mounted && isLoading) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveNotificationsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(notifications);
    await prefs.setString('saved_notifications', encodedData);
  }

  // ==============================================================================
  // 2. الربط اللحظي المطور المعزول سيبرانياً (Secure Socket.io Listener)
  // ==============================================================================
  void setupSocketListener() {
    final pharmacyId = AuthService.currentPharmacy?['id'];

    // 💡 الحصن القياسي: جلب التوكن الرقمي الموثق للصيدلي بدلاً من الـ ID النصي القديم
    // (تأكد من مطابقة مسمى المتغير token أو currentAdminToken حسب المتاح بملف الحماية بجوالك)
    final String? userToken = AuthService.token;

    if (pharmacyId == null || userToken == null) return;

    // استدعاء دالة الاتصال القياسية المحدثة وحقن معالج الاستقبال بداخلها مباشرة
    SocketService.connect(userToken, (data) {
      if (mounted) {
        setState(() {
          // دفع الإشعار اللحظي القفّاز فوراً إلى أعلى القائمة أمام الصيدلي
          _pushNewNotification(
            title: data['title'] ?? "تنبيه جديد 🔔",
            message: data['message'] ?? "",
          );
        });

        // إطلاق لافتة التنبيه المنبثقة العلوية بداخل التطبيق
        NotificationService.showNotification(
          context,
          message: data['message'] ?? "لديك إشعار جديد",
          isSuccess: true,
        );
      }
    });
  }

  void _pushNewNotification({required String title, required String message}) {
    if (mounted) {
      setState(() {
        notifications.insert(0, {
          "title": title,
          "body": message,
          "time": "الآن",
          "is_read": false
        });
      });
      _saveNotificationsToStorage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("مركز الإشعارات",
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.red),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('saved_notifications');
              setState(() => notifications.clear());
            },
          )
        ],
      ),
      body: Directionality(
        textDirection: TextDirection
            .rtl, // إضافة التوجيه العربي لضمان تنسيق النصوص والمحاذاة
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF007A87)))
            : notifications.isEmpty
                ? const Center(
                    child: Text("لا توجد إشعارات حالياً",
                        style: TextStyle(fontFamily: 'Cairo')))
                : RefreshIndicator(
                    color: const Color(0xFF007A87),
                    onRefresh:
                        _loadStoredNotifications, // ميزة السحب لأسفل لمزامنة الإشعارات مع قاعدة البيانات يدوياً
                    child: _buildNotificationsList(),
                  ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final item = notifications[index];
        bool isUnread = item['is_read'] == false;
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: isUnread
                    ? const Color(0xFF007A87)
                    : const Color(0xFFE2E8F0)),
          ),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(item['title'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            subtitle: Text(item['body'] ?? '',
                style: const TextStyle(fontFamily: 'Cairo')),
            trailing: Icon(Icons.circle,
                size: 10,
                color: isUnread ? const Color(0xFF007A87) : Colors.transparent),
          ),
        );
      },
    );
  }
}
