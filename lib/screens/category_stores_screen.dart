import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import 'package:speedgo_client/screens/store_screen.dart';

class CategoryStoresScreen extends StatefulWidget {
  final SupabaseClient supabase;
  final String categoryName;
  final String categoryImage;
  final List<Color> gradientColors;

  const CategoryStoresScreen({
    super.key,
    required this.supabase,
    required this.categoryName,
    required this.categoryImage,
    required this.gradientColors,
  });

  @override
  State<CategoryStoresScreen> createState() => _CategoryStoresScreenState();
}

class _CategoryStoresScreenState extends State<CategoryStoresScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _doorController;
  late Animation<double> _doorOpenAnimation;
  late Animation<double> _fadeContentAnimation;

  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = true;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _doorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // حركة انقسام البوابة للخارج (من 0 إلى 1)
    _doorOpenAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _doorController,
        curve: const Interval(0.2, 0.85, curve: Curves.easeInOutCubic),
      ),
    );

    // ظهور المحتوى الداخلي عند اتساع الانقسام
    _fadeContentAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _doorController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _doorController.forward();
    _fetchCategoryStoresOnly();
  }

  @override
  void dispose() {
    _doorController.dispose();
    super.dispose();
  }

  // جلب متاجر هذا القسم بشكل صارم وحصري
  Future<void> _fetchCategoryStoresOnly() async {
    try {
      final res = await widget.supabase.from('stores').select();
      if (mounted) {
        final list = List<Map<String, dynamic>>.from(res as List);
        
        // تصفية صارمة: جلب المتاجر التي يطابق قسمها اسم القسم المختار فقط
        final filtered = list.where((s) {
          final cat = (s['category'] ?? '').toString().trim().toLowerCase();
          final targetCat = widget.categoryName.trim().toLowerCase();
          return cat == targetCat || cat.contains(targetCat) || targetCat.contains(cat);
        }).toList();

        setState(() {
          _stores = filtered; // إسناد المتاجر المفلترة فقط بدون إرجاع القائمة الكاملة
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  TextStyle _tajawal({required double size, required FontWeight weight, Color color = const Color(0xFF1A1A1A)}) {
    return GoogleFonts.tajawal(fontSize: size, fontWeight: weight, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFEEF),
        body: Stack(
          children: [
            // 1. المحتوى الداخلي (المتاجر الخاصة بالقسم) يظهر خلف البوابة
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeContentAnimation,
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildViewToggle(),
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF25C05)))
                            : _stores.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.storefront_outlined, size: 50, color: Color(0xFF9E9E9E)),
                                        const SizedBox(height: 12),
                                        Text(
                                          'لا توجد متاجر مضافة في قسم (${widget.categoryName}) حالياً',
                                          style: _tajawal(size: 15, weight: FontWeight.w700, color: const Color(0xFF757575)),
                                        ),
                                      ],
                                    ),
                                  )
                                : _isGridView ? _buildGridList() : _buildVerticalList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. انقسام بطاقة القسم إلى نصفين كالبوابة (Door Split Effect)
            AnimatedBuilder(
              animation: _doorController,
              builder: (context, child) {
                final splitOffset = _doorOpenAnimation.value * (size.width / 2);
                if (_doorOpenAnimation.value >= 0.98) {
                  return const SizedBox.shrink(); // إخفاء البوابة بعد اكتمال الانقسام
                }

                return Stack(
                  children: [
                    // النصف الأيمن للبطاقة المنقسمة
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: -splitOffset,
                      width: size.width / 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: widget.gradientColors,
                          ),
                        ),
                        child: Center(
                          child: Opacity(
                            opacity: (1.0 - _doorOpenAnimation.value).clamp(0.0, 1.0),
                            child: Text(
                              widget.categoryName,
                              style: _tajawal(size: 22, weight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // النصف الأيسر للبطاقة المنقسمة
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: -splitOffset,
                      width: size.width / 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: widget.gradientColors,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A), size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Text('متاجر ${widget.categoryName}', style: _tajawal(size: 20, weight: FontWeight.w900)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isGridView = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isGridView ? const Color(0xFFF25C05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.format_list_bulleted, size: 18, color: !_isGridView ? Colors.white : const Color(0xFF757575)),
                    const SizedBox(width: 6),
                    Text('قائمة', style: _tajawal(size: 14, weight: FontWeight.w800, color: !_isGridView ? Colors.white : const Color(0xFF757575))),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isGridView = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isGridView ? const Color(0xFFF25C05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_view_rounded, size: 18, color: _isGridView ? Colors.white : const Color(0xFF757575)),
                    const SizedBox(width: 6),
                    Text('شبكة', style: _tajawal(size: 14, weight: FontWeight.w800, color: _isGridView ? Colors.white : const Color(0xFF757575))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalList() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _stores.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildStoreCardList(_stores[index]);
      },
    );
  }

  Widget _buildStoreCardList(Map<String, dynamic> store) {
    final storeId = store['id']?.toString() ?? '';
    final name = store['name'] ?? store['store_name'] ?? 'متجر غير مسمى';
    final cat = store['category'] ?? widget.categoryName;
    final img = store['logo_url'] ?? widget.categoryImage;

    return GestureDetector(
      onTap: () {
        if (storeId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoreScreen(supabase: widget.supabase, storeId: storeId),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
                      const SizedBox(width: 4),
                      Text('4.5', style: _tajawal(size: 12, weight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFFF2EB), borderRadius: BorderRadius.circular(10)),
                  child: Text('قَيِّم المتجر', style: _tajawal(size: 11, weight: FontWeight.w800, color: const Color(0xFFF25C05))),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(name, style: _tajawal(size: 16.5, weight: FontWeight.w900)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(6)),
                  child: Text(cat, style: _tajawal(size: 11, weight: FontWeight.w600, color: const Color(0xFF757575))),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('30 دقيقة', style: _tajawal(size: 11.5, weight: FontWeight.w700, color: const Color(0xFF5C677D))),
                    const SizedBox(width: 4),
                    const Icon(Icons.access_time_filled, size: 13, color: Color(0xFFF25C05)),
                    const SizedBox(width: 10),
                    Text('سريع', style: _tajawal(size: 11.5, weight: FontWeight.w700, color: const Color(0xFF2A9D8F))),
                    const SizedBox(width: 4),
                    const Icon(Icons.delivery_dining, size: 15, color: Color(0xFFF25C05)),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                img,
                width: 75,
                height: 75,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 75, height: 75, color: const Color(0xFFF5F5F5), child: const Icon(Icons.store, color: Color(0xFFBDBDBD))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridList() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 210,
      ),
      itemCount: _stores.length,
      itemBuilder: (context, index) {
        final store = _stores[index];
        final storeId = store['id']?.toString() ?? '';
        final name = store['name'] ?? store['store_name'] ?? 'متجر غير مسمى';
        final img = store['logo_url'] ?? widget.categoryImage;

        return GestureDetector(
          onTap: () {
            if (storeId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreScreen(supabase: widget.supabase, storeId: storeId),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    img,
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 90, color: const Color(0xFFF5F5F5)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(name, style: _tajawal(size: 15, weight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB300)),
                    const SizedBox(width: 4),
                    Text('4.5', style: _tajawal(size: 12, weight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    Text('30 دقيقة', style: _tajawal(size: 11, weight: FontWeight.w700, color: const Color(0xFF757575))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
