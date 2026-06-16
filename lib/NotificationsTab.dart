// ignore_for_file: file_names

import 'dart:convert'; // ضروري جداً لعمليات الحفظ (jsonEncode/Decode)
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
    _loadStoredNotifications(); // 1. جلب الإشعارات المحفوظة في الهاتف فور تشغيل الصفحة
    setupSocketListener(); // 2. ربط السوكيت
  }

  // ==========================================
  // 1. منطق التخزين الدائم (Shared Preferences)
  // ==========================================

  Future<void> _loadStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedData = prefs.getString('saved_notifications');

    if (storedData != null) {
      if (mounted) {
        setState(() {
          notifications =
              List<Map<String, dynamic>>.from(jsonDecode(storedData));
          isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveNotificationsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(notifications);
    await prefs.setString('saved_notifications', encodedData);
  }

  // ==========================================
  // 2. الربط اللحظي المطور (Socket.io)
  // ==========================================
  void setupSocketListener() {
    final pharmacyId = AuthService.currentPharmacy?['id'];
    if (pharmacyId == null) return;

    // 1️⃣ استدعاء الاتصال العالمي ليظل السوكيت يعمل في كل التطبيق
    SocketService.connect(pharmacyId.toString());

    // 2️⃣ هنا نستمع للسوكيت داخل الصفحة لعرض الإشعار في القائمة فوراً إذا كانت الصفحة مفتوحة
    SocketService.socket.on("notification_$pharmacyId", (data) {
      if (mounted) {
        setState(() {
          _pushNewNotification(
            title: data['title'] ?? "تنبيه جديد 🔔",
            message: data['message'] ?? "",
          );
        });

        // 3️⃣ إظهار الإشعار المحلي للمستخدم فوق الشاشة
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
      // 💾 حفظ في الهاتف لضمان عدم ضياع الإشعارات عند إغلاق التطبيق
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
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF007A87)))
          : notifications.isEmpty
              ? const Center(
                  child: Text("لا توجد إشعارات حالياً",
                      style: TextStyle(fontFamily: 'Cairo')))
              : _buildNotificationsList(),
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
            title: Text(item['title'],
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
            subtitle:
                Text(item['body'], style: const TextStyle(fontFamily: 'Cairo')),
            trailing: Icon(Icons.circle,
                size: 10,
                color: isUnread ? const Color(0xFF007A87) : Colors.transparent),
          ),
        );
      },
    );
  }
}
