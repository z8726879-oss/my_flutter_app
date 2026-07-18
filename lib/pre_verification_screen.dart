import 'package:flutter/material.dart';
import 'dart:convert'; // مكتبة لتفكيك بيانات الـ JSON القادمة من السيرفر
import 'package:http/http.dart'
    as http; // استدعاء مباشر ومستقل لحل مشكلة الـ ApiService
import 'register_screen.dart';

class PreVerificationScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const PreVerificationScreen({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _PreVerificationScreenState createState() => _PreVerificationScreenState();
}

class _PreVerificationScreenState extends State<PreVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  final String _warehousePhone = "0933xxxxxx";

  // 💡 تم التعديل إلى false لكي لا تفتح الصفحة وهي في حالة تحميل مستمر
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  // 💡 تنظيف الذاكرة عند مغادرة الصفحة
  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // دالة التحقق من الرمز عبر السيرفر مباشرة (أعلى درجات الأمان لمنع التخمين)
  Future<void> _verifyCode() async {
    String enteredCode = _codeController.text.trim();

    if (enteredCode.isEmpty) {
      _showErrorSnackBar("يرجى إدخال رمز التسجيل أولاً!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse(
          'http://192.168.43.68:5000/api/auth/verify-registration-code');

      // 💡 تعديل الترويسات لتشمل قبول جميع أنواع الاستجابات وتجنب حظر الأندرويد
      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json; charset=UTF-8",
              "Accept": "application/json",
            },
            body: jsonEncode({
              'clientCode': enteredCode,
            }),
          )
          .timeout(const Duration(seconds: 7)); // وضع حد أقصى للانتظار 7 ثوانٍ

      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });

        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const RegisterScreen()),
        );
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar(data['message'] ??
            'الرمز السري غير صحيح! يرجى مراجعة إدارة المستودع.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // 💡 طباعة الخطأ الحقيقي داخل الفلاتر لمعرفة سبب الحظر (انظر إلى الـ Debug Console في VS Code)
      // ignore: avoid_print
      print("🚨 خطأ اتصال الفلاتر بالشبكة: $e");

      _showErrorSnackBar(
          "تأكد من اتصال الجوال بنفس شبكة السيرفر ومطابقة الرمز!");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(
          message,
          textAlign: TextAlign.center,
          style:
              const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        // تعطيل زر الرجوع أثناء عملية التحميل لحماية تدفق البيانات
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF007A87)),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.lock_person_rounded,
                    size: 80,
                    color: Color(0xFF007A87),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "بوابة التحقق الخاصة بالمستودع",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Color(0xFF1A202C)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "لإنشاء حساب جديد، يرجى إدخال الرمز السري الموحد الممنوح لكم من قبل مندوب المستودع.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, fontFamily: 'Cairo', color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    // تعطيل حقل النص أثناء التحميل لمنع التعديل عليه أثناء إرسال الطلب
                    enabled: !_isLoading,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "أدخل الرمز السري هنا",
                      hintStyle: const TextStyle(
                          letterSpacing: 0,
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: Colors.grey),
                      prefixIcon: const Icon(Icons.vpn_key_rounded,
                          color: Color(0xFF007A87)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                            color: Color(0xFF007A87), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    // إذا كان في حالة تحميل، يتم تمرير null لتعطيل الزر ومنع الطلبات المكررة
                    onPressed: _isLoading ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A87),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 0,
                    ),
                    // تفعيل حركة مؤشر التحميل داخل الزر نفسه بدلاً من إخفاء الشاشة
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "تأكيد الرمز والمتابعة",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 40),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 16),
                  const Text(
                    "لا تملك الرمز السري أو تواجه مشكلة؟",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, fontFamily: 'Cairo', color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF007A87)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      "رقم المستودع للمراجعة: $_warehousePhone",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          color: Color(0xFF007A87)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
