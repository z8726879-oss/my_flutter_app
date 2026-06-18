import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../cart_service.dart';
import '../cart_item.dart';

class DrugsScreen extends StatefulWidget {
  final int companyId;
  final String companyName;

  const DrugsScreen({
    super.key,
    required this.companyId,
    required this.companyName,
  });

  @override
  State<DrugsScreen> createState() => _DrugsScreenState();
}

class _DrugsScreenState extends State<DrugsScreen> {
  List allDrugs = [];
  List filteredDrugs = [];
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDrugs();
  }

  Future<void> fetchDrugs() async {
    try {
      final data = await ApiService.getDrugsByCompany(widget.companyId);
      if (mounted) {
        setState(() {
          allDrugs = data;
          filteredDrugs = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void filterDrugs(String query) {
    setState(() {
      filteredDrugs = allDrugs
          .where((drug) => drug["name"]
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          "مستحضرات ${widget.companyName}",
          style: const TextStyle(
              color: Color(0xFF007A87),
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              fontSize: 16),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF007A87), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF007A87)))
                : filteredDrugs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: filteredDrugs.length,
                        itemBuilder: (context, index) {
                          return DrugItemCard(
                            key: ValueKey(filteredDrugs[index]["id"]),
                            drug: filteredDrugs[index],
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white,
      child: TextField(
        controller: searchController,
        onChanged: filterDrugs,
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: "ابحث عن اسم الدواء...",
          hintStyle: const TextStyle(
              fontFamily: 'Cairo', fontSize: 13, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF007A87)),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    searchController.clear();
                    filterDrugs("");
                  })
              : null,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 50, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text("لم نجد الدواء المطلوب",
              style: TextStyle(fontFamily: 'Cairo', color: Colors.grey)),
        ],
      ),
    );
  }
}

class DrugItemCard extends StatefulWidget {
  final Map drug;
  const DrugItemCard({super.key, required this.drug});

  @override
  State<DrugItemCard> createState() => _DrugItemCardState();
}

class _DrugItemCardState extends State<DrugItemCard> {
  int selectedQty = 1;

  void addToCart() {
    CartService.addItem(
      CartItem(
        drugId: widget.drug["id"] ?? 0,
        name: widget.drug["name"] ?? "مستحضر",
        price: double.parse(widget.drug["price"].toString()),
        offer: widget.drug["offer"] ?? "لا يوجد عرض",
        quantity: selectedQty,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF007A87),
        behavior: SnackBarBehavior.floating,
        content: Text("تمت إضافة $selectedQty من ${widget.drug["name"]} للسلة",
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _buildDrugImage(String? imageStr) {
    if (imageStr == null || imageStr.isEmpty || imageStr.length < 10) {
      return const Icon(
        Icons.medication_rounded,
        size: 40,
        color: Color(0xFF007A87),
      );
    }

    // إذا كان النص القادم يحتوي على رابط يبدأ بـ http، نقوم بعرضه فوراً كصورة شبكية سريعة
    if (imageStr.startsWith('http')) {
      return Image.network(
        imageStr,
        fit: BoxFit.contain,
        // مؤشر تحميل خفيف جداً يظهر أثناء تحميل الصورة لأول مرة
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
            const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    }

    // كود احتياطي (Fallback) في حال وجود صور قديمة في السيرفر لا تزال بصيغة Base64
    try {
      return Image.memory(
        base64Decode(imageStr),
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      );
    } catch (e) {
      return const Icon(Icons.broken_image, size: 40, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? offer = widget.drug["offer"];
    final String? drugImage = widget.drug["image"];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              // تم تكبير مساحة الصورة لتعطي فخامة ووضوح
              leading: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildDrugImage(drugImage),
                ),
              ),
              title: Text(
                widget.drug["name"] ?? "",
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: Color(0xFF1E293B)),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (offer != null && offer.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "عرض: $offer",
                          style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo'),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      "السعر: ${widget.drug["price"]} ل.س",
                      style: const TextStyle(
                          color: Color(0xFF007A87),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo'),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A87),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                  label: const Text("إضافة",
                      style: TextStyle(
                          fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          color: Colors.grey, size: 24),
                      onPressed: () => setState(() {
                        if (selectedQty > 1) selectedQty--;
                      }),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        "$selectedQty",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          color: Color(0xFF007A87), size: 24),
                      onPressed: () => setState(() => selectedQty++),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
