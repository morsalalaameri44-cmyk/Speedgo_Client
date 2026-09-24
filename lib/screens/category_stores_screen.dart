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
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _stores = [];
  bool _isLoading = true;
  bool _isGridView = false; // نمط العرض: false = قائمة، true = شبكة

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _fetchCategoryStores();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategoryStores() async {
    try {
      final res = await widget.supabase.from('stores').select();
      if (mounted) {
        final list = List<Map<String, dynamic>>.from(res as List);
        final filtered = list.where((s) {
          final cat = (s['category'] ?? '').toString().toLowerCase();
          return cat.contains(widget.categoryName.toLowerCase());
        }).toList();

        setState(() {
          _stores = filtered.isNotEmpty ? filtered : list;
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFEEF),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A), size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'متاجر ${widget.categoryName}',
            style: _tajawal(size: 20, weight: FontWeight.w900),
          ),
          centerTitle: true,
        ),
        body: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildViewToggle(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFF25C05)))
                      : _stores.isEmpty
                          ? Center(child: Text('لا توجد متاجر متاحة حالياً', style: _tajawal(size: 15, weight: FontWeight.w700, color: const Color(0xFF757575))))
                          : _isGridView ? _buildGridList() : _buildVerticalList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(16),
      ),
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
        final store = _stores[index];
        return _buildStoreCardList(store);
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
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
                errorBuilder: (_, __, ___) => Container(
                  width: 75,
                  height: 75,
                  color: const Color(0xFFF5F5F5),
                  child: const Icon(Icons.store, color: Color(0xFFBDBDBD)),
                ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
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
