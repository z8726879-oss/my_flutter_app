import 'package:flutter/material.dart';
import 'package:my_new_app/main_navigation_screen.dart'; // التعديل هنا: استيراد MainNavigationScreen بدلاً من CompaniesScreen

import 'register_screen.dart';
import 'services/auth_service.dart'; // التعديل هنا: استيراد auth_service بدلاً من api_service

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // دالة تسجيل الدخول (LOGIN FUNCTION)
  // ==========================================
  Future<void> login() async {
    if (phoneController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى إدخال رقم الهاتف وكلمة المرور"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // التعديل هنا: استدعاء AuthService وتمرير البارامترات بأسمائها الصحيحة
      await AuthService.login(
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
      );

      // التحقق الآمن من وجود الواجهة قبل الانتقال
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(),
          ), // الانتقال لصفحة التبويبات وليس الشركات فقط
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("خطأ: ${e.toString().replaceAll('Exception: ', '')}"),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ==========================================
  // واجهة المستخدم (UI Build)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // خلفية بيضاء مريحة
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "تسجيل دخول الصيادلة",
          style: TextStyle(
            color: Color(0xFF007A87),
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // شعار طبي فخم متناسق مع ألوان المستودع
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: const Color(0xFF007A87).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_pharmacy,
                  size: 80,
                  color: Color(0xFF007A87), // الأزرق الطبي
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "مستودع الأدوية الذكي",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  fontFamily: 'Cairo',
                ),
              ),
              const Text(
                "بوابة الصيدلي لطلب الأدوية ومتابعة العروض",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'Cairo',
                ),
              ),

              const SizedBox(height: 32),

              // حقل الهاتف (PHONE)
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: "رقم الهاتف المسجل",
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF007A87)),
                ),
              ),

              const SizedBox(height: 16),

              // حقل كلمة المرور (PASSWORD)
              TextField(
                controller: passwordController,
                obscureText: true,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  labelText: "كلمة المرور",
                  labelStyle: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF007A87)),
                ),
              ),

              const SizedBox(height: 32),

              // زر تسجيل الدخول (LOGIN BUTTON)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A87),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "دخول للنظام",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // إنشاء حساب جديد (REGISTER LINK)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  "ليس لديك حساب؟ أنشئ حساباً صيدلانياً جديداً",
                  style: TextStyle(
                    color: Color(0xFF007A87),
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
