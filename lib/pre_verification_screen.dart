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
  String _dynamicWarehouseCode = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentCode();
  }

  // دالة جلب الرمز المستقلة تماماً لحل مشكلة الخطأ الأحمر
  Future<void> _fetchCurrentCode() async {
    try {
      // ملاحظة: إذا كنت تختبر الجوال على هاتف حقيقي والسيرفر على الكمبيوتر،
      // استبدل localhost برقم الآيبي (IP) الفعلي للكمبيوتر (مثال: 192.168.1.5)
      final url = Uri.parse('http://localhost:3000/api/auth/registration-code');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] != null) {
          setState(() {
            _dynamicWarehouseCode = data['code'].toString().trim();
            _isLoading = false;
          });
        }
      } else {
        _showErrorSnackBar("فشل جلب رمز التحقق من السيرفر!");
      }
    } catch (e) {
      _showErrorSnackBar("تأكد من اتصال الجوال بالإنترنت لمطابقة الرمز!");
    }
  }

  void _verifyCode() {
    String enteredCode = _codeController.text.trim();
    if (enteredCode == _dynamicWarehouseCode &&
        _dynamicWarehouseCode.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RegisterScreen()),
      );
    } else {
      _showErrorSnackBar('الرمز السري غير صحيح! يرجى مراجعة إدارة المستودع.');
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF007A87)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF007A87)))
                : SingleChildScrollView(
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
                              fontSize: 13,
                              fontFamily: 'Cairo',
                              color: Colors.grey),
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _codeController,
                          textAlign: TextAlign.center,
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
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide:
                                  const BorderSide(color: Color(0xFFE2E8F0)),
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
                          onPressed: _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007A87),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            elevation: 0,
                          ),
                          child: const Text(
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
                              fontSize: 12,
                              fontFamily: 'Cairo',
                              color: Colors.grey),
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
