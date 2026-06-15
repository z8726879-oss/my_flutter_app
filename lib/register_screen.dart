import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ضروري لتحديد نوع المدخلات
import 'login_screen.dart';
import 'services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final cityController = TextEditingController();
  final addressController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    cityController.dispose();
    addressController.dispose();
    super.dispose();
  }

  // ==========================================
  // دالة إنشاء الحساب المحدثة
  // ==========================================
  Future<void> handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await AuthService.register(
        pharmacyName: nameController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
        city: cityController.text.trim(),
        address: addressController.text.trim(),
        // تم حذف حقل الرخصة من هنا
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text("تم إنشاء حساب الصيدلية بنجاح!",
                style: TextStyle(fontFamily: 'Cairo')),
          ),
        );
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
                "فشل التسجيل: ${e.toString().replaceAll('Exception: ', '')}",
                style: const TextStyle(fontFamily: 'Cairo')),
          ),
        );
      }
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text("إنشاء حساب جديد",
            style: TextStyle(
                color: Color(0xFF007A87),
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                fontSize: 18)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.local_pharmacy_rounded,
                    size: 70, color: Color(0xFF007A87)),
                const SizedBox(height: 12),
                const Text("انضم لشبكة عملائنا",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 28),

                _buildInputField(
                  controller: nameController,
                  label: "اسم الصيدلية",
                  icon: Icons.business,
                ),
                const SizedBox(height: 14),

                // حقل الهاتف المحدث (10 أرقام فقط)
                _buildInputField(
                  controller: phoneController,
                  label: "رقم الجوال (10 أرقام)",
                  icon: Icons.phone_android,
                  keyType: TextInputType.phone,
                  isPhone: true, // تفعيل شرط الـ 10 أرقام
                ),
                const SizedBox(height: 14),

                _buildInputField(
                  controller: passwordController,
                  label: "كلمة المرور",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                const SizedBox(height: 14),

                _buildInputField(
                  controller: cityController,
                  label: "المدينة",
                  icon: Icons.location_city,
                ),
                const SizedBox(height: 14),

                _buildInputField(
                  controller: addressController,
                  label: "العنوان بالتفصيل",
                  icon: Icons.map_outlined,
                ),
                const SizedBox(height: 28),

                // زر التسجيل
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A87),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : const Text("إرسال طلب التسجيل",
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Cairo',
                                color: Colors.white)),
                  ),
                ),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("لديك حساب؟ سجل دخولك الآن",
                      style: TextStyle(
                          color: Color(0xFF007A87),
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // أداة بناء الحقول الذكية
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isPhone = false,
    TextInputType keyType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyType,
      textAlign: TextAlign.right,
      maxLength: isPhone ? 10 : null, // تحديد الحد الأقصى بـ 10 للهاتف
      inputFormatters: isPhone
          ? [FilteringTextInputFormatter.digitsOnly]
          : [], // منع الحروف في حقل الهاتف
      decoration: InputDecoration(
        labelText: label,
        counterText: "", // إخفاء عداد الحروف لجمالية التصميم
        labelStyle: const TextStyle(
            fontFamily: 'Cairo', fontSize: 13, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: const Color(0xFF007A87)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
        if (isPhone && value.length != 10)
          // ignore: curly_braces_in_flow_control_structures
          return 'يجب أن يكون رقم الجوال 10 أرقام';
        return null;
      },
    );
  }
}
