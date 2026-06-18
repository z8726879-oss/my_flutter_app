import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'drugs_screen.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  List allCompanies = []; // القائمة الكاملة من السيرفر
  List filteredCompanies = []; // القائمة المفلترة التي تظهر في الواجهة
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCompanies();
  }

  // ==========================================
  // جلب البيانات (LOAD DATA)
  // ==========================================
  Future<void> loadCompanies() async {
    try {
      final data = await ApiService.getCompanies();
      if (mounted) {
        setState(() {
          allCompanies = data;
          filteredCompanies = data; // في البداية نعرض الكل
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ==========================================
  // دالة البحث الذكي (SEARCH LOGIC)
  // ==========================================
  void filterSearch(String query) {
    setState(() {
      filteredCompanies = allCompanies
          .where((company) => company["name"]
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // شريط البحث الفخم في الأعلى
          _buildSearchField(),

          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF007A87)))
                : RefreshIndicator(
                    onRefresh: loadCompanies,
                    color: const Color(0xFF007A87),
                    child: filteredCompanies.isEmpty
                        ? _buildEmptyState()
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: filteredCompanies.length,
                            itemBuilder: (context, index) =>
                                _buildCompanyCard(filteredCompanies[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // تصنيع حقل البحث الاحترافي
  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      color: Colors.white,
      child: TextField(
        controller: searchController,
        onChanged: filterSearch,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: "ابحث عن شركة دوائية...",
          hintStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 13, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF007A87)),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    searchController.clear();
                    filterSearch("");
                  })
              : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // (بقية الدوال: _buildCompanyCard و _buildCompanyImage تبقى كما هي في الكود السابق)

  Widget _buildCompanyCard(Map company) {
    final int companyId = company["id"] ?? 0;
    final String companyName = company["name"] ?? "شركة دوائية";
    final String? companyImage = company["image"];

    return GestureDetector(
      onTap: () {
        if (companyId != 0) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => DrugsScreen(
                      companyId: companyId, companyName: companyName)));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 80,
              width: 80,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildCompanyImage(companyImage)),
            ),
            const SizedBox(height: 12),
            Text(companyName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyImage(String? imageStr) {
    if (imageStr == null || imageStr.isEmpty || imageStr.length < 10) {
      return const Icon(
        Icons.business_rounded,
        size: 36,
        color: Color(0xFF007A87),
      );
    }

    // إذا كان النص القادم يحتوي على رابط يبدأ بـ http، نقوم بعرضه فوراً كصورة شبكية سريعة
    if (imageStr.startsWith('http')) {
      return Image.network(
        imageStr,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF007A87)),
            ),
          );
        },
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, size: 36, color: Colors.grey),
      );
    }

    // كود احتياطي لدعم نظام الـ Base64 القديم إن وُجد لحماية استقرار التطبيق
    try {
      return Image.memory(
        base64Decode(imageStr),
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, size: 36, color: Colors.grey),
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 36, color: Colors.grey);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text("لم نجد شركة بهذا الاسم",
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
        ],
      ),
    );
  }
}
