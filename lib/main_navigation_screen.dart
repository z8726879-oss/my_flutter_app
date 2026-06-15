import 'package:flutter/material.dart';
// استيراد الشاشات الخاصة بك
import 'companies_screen.dart';
import 'cart_screen.dart';
import 'requests_screen.dart';
import 'balance_tab.dart';
import 'NotificationsTab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // تعريف الـ 5 تبويبات
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "مستودع الأدوية الذكي",
          style: TextStyle(
              color: Color(0xFF007A87),
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo'),
        ),
        centerTitle: true,
        // إضافة الأيقونات الخمسة في أسفل الـ AppBar لسهولة التنقل
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF007A87),
          labelColor: const Color(0xFF007A87),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 10, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.business_rounded), text: "الشركات"),
            Tab(icon: Icon(Icons.shopping_cart_rounded), text: "السلة"),
            Tab(icon: Icon(Icons.receipt_long_rounded), text: "الطلبات"),
            Tab(
                icon: Icon(Icons.account_balance_wallet_rounded),
                text: "الرصيد"),
            Tab(
                icon: Icon(Icons.notifications_active_rounded),
                text: "الإشعارات"),
          ],
        ),
      ),
      // هنا تظهر الصفحات بناءً على التبويب المختار
      body: TabBarView(
        controller: _tabController,
        children: const [
          CompaniesScreen(), // أيقونة 1
          CartScreen(), // أيقونة 2
          RequestsScreen(), // أيقونة 3
          PharmacyBalanceTab(), // أيقونة 4
          PharmacyNotificationsTab(), // أيقونة 5
        ],
      ),
    );
  }
}
