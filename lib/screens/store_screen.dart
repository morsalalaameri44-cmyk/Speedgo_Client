import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

class StoreScreen extends StatefulWidget {
  final SupabaseClient supabase;
  final String storeId;

  const StoreScreen({
    super.key,
    required this.supabase,
    required this.storeId,
  });

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  Map<String, dynamic>? _store;
  Map<String, List<Map<String, dynamic>>> _groupedProducts = {};
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = '';

  int _cartCount = 0;
  num _cartTotal = 0;
  final Set<String> _animatingProductIds = {};

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  @override
  void initState() {
    super.initState();
    _fetchStoreAndProducts();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getDefaultCoverByCategory(String? category) {
    final cat = (category ?? '').toLowerCase();
    if (cat.contains('مطعم') || cat.contains('مطاعم')) {
      return 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=600&q=80';
    }
    if (cat.contains('سوبر ماركت') || cat.contains('بقالة')) {
      return 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80';
    }
    if (cat.contains('صيدل') || cat.contains('أدوية')) {
      return 'https://images.unsplash.com/photo-1585435557343-3b092031a831?auto=format&fit=crop&w=600&q=80';
    }
    if (cat.contains('تحف') || cat.contains('هدايا')) {
      return 'https://images.unsplash.com/photo-1513201099705-a9746e1e201f?auto=format&fit=crop&w=600&q=80';
    }
    if (cat.contains('مكتب')) {
      return 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?auto=format&fit=crop&w=600&q=80';
    }
    if (cat.contains('إلكترون') || cat.contains('جوال')) {
      return 'https://images.unsplash.com/photo-1498049794561-7780e7231661?auto=format&fit=crop&w=600&q=80';
    }
    return 'https://images.unsplash.com/photo-1472851294608-062f824d29cc?auto=format&fit=crop&w=600&q=80';
  }

  Future<void> _fetchStoreAndProducts() async {
    try {
      final storeRes = await widget.supabase
          .from('stores')
          .select()
          .eq('id', widget.storeId)
          .maybeSingle();

      final prodRes = await widget.supabase
          .from('products')
          .select()
          .eq('store_id', widget.storeId);

      if (mounted) {
        final products = (prodRes as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        final Map<String, List<Map<String, dynamic>>> groups = {};
        for (var p in products) {
          final cat = (p['category'] ?? p['category_name'] ?? 'أصناف عامة').toString();
          groups.putIfAbsent(cat, () => []).add(p);
          _categoryKeys.putIfAbsent(cat, () => GlobalKey());
        }

        setState(() {
          _store = storeRes != null ? Map<String, dynamic>.from(storeRes as Map) : null;
          _groupedProducts = groups;
          if (groups.isNotEmpty) {
            _selectedCategory = groups.keys.first;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    final key = _categoryKeys[category];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.14,
      );
    }
  }

  void _addToCart(String productId, num price) {
    setState(() {
      _animatingProductIds.add(productId);
      _cartCount++;
      _cartTotal += price;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _animatingProductIds.remove(productId);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: ThemeData(textTheme: GoogleFonts.tajawalTextTheme()),
        child: Scaffold(
          backgroundColor: const Color(0xFFFDFDFD),
          body: Stack(
            children: [
              if (_isLoading)
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFF25C05)),
                      SizedBox(height: 16),
                      Text(
                        'جاري جلب الأصناف والتصنيفات...',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1A1A1A)),
                      ),
                    ],
                  ),
                )
              else if (_errorMessage != null || _store == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _errorMessage ?? 'لم يتم العثور على المتجر المطلوب',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                )
              else
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCoverSection(),
                      _buildStoreDetailsCard(),
                      if (_groupedProducts.isNotEmpty) _buildCategoriesTabs(),
                      _buildProductsList(),
                    ],
                  ),
                ),

              // الهيدر الزجاجي
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildGlassHeader(),
              ),

              // شريط السلة العائم
              if (_cartCount > 0)
                Positioned(
                  bottom: 22,
                  left: 20,
                  right: 20,
                  child: _buildFloatingCartBar(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 14,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.3))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF1A1A1A), size: 22),
                ),
              ),
              const Text(
                'قائمة الأصناف',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ رابط المتجر!')),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.share_outlined, color: Color(0xFF1A1A1A), size: 21),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverSection() {
    final cat = _store?['category']?.toString();
    String cover = (_store?['cover_url'] ?? '').toString();
    if (cover.trim().isEmpty) cover = (_store?['logo_url'] ?? '').toString();
    if (cover.trim().isEmpty) cover = _getDefaultCoverByCategory(cat);

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            cover,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEFEFEF)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreDetailsCard() {
    final name = _store?['name'] ?? _store?['store_name'] ?? 'متجر غير معروف';
    final cat = _store?['category'] ?? 'عام';

    return Container(
      transform: Matrix4.translationValues(0, -40, 0),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text(cat, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF757575))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.star_rounded, '4.9'),
                _buildStatItem(Icons.access_time_filled_rounded, '30 دقيقة'),
                _buildStatItem(Icons.delivery_dining_rounded, 'توصيل سريع'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFF25C05), size: 24),
        const SizedBox(height: 6),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
      ],
    );
  }

  Widget _buildCategoriesTabs() {
    return Container(
      transform: Matrix4.translationValues(0, -20, 0),
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _groupedProducts.keys.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = _groupedProducts.keys.elementAt(index);
          final isSelected = cat == _selectedCategory;

          return GestureDetector(
            onTap: () => _scrollToCategory(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF25C05) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFFF25C05) : const Color(0xFFF0F0F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected ? const Color(0xFFF25C05).withOpacity(0.25) : Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : const Color(0xFF616161),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsList() {
    if (_groupedProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.inventory_2_outlined, size: 55, color: Color(0xFFCCCCCC)),
              SizedBox(height: 14),
              Text(
                'لا توجد أصناف مضافة في هذا المتجر حالياً.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF757575)),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _groupedProducts.entries.map((entry) {
          final catName = entry.key;
          final products = entry.value;

          return Container(
            key: _categoryKeys[catName],
            margin: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  catName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 14),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final p = products[index];
                    final pId = p['id']?.toString() ?? index.toString();
                    final pName = p['name'] ?? 'منتج غير مسمى';
                    final pDesc = p['description']?.toString() ?? '';
                    final pPrice = (p['price'] is num) ? p['price'] as num : 0;
                    final pImg = p['image_url'] ?? 'https://via.placeholder.com/150/F8F9FA/757575?text=بدون+صورة';
                    final isAdding = _animatingProductIds.contains(pId);

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              pImg,
                              width: 95,
                              height: 95,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 95,
                                height: 95,
                                color: const Color(0xFFF5F5F5),
                                child: const Icon(Icons.fastfood_rounded, color: Color(0xFFBDBDBD), size: 36),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pName,
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (pDesc.isNotEmpty) ...[
                                  const SizedBox(height: 5),
                                  Text(
                                    pDesc,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF757575), height: 1.35, fontWeight: FontWeight.w500),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${pPrice.toString()} ر.ي',
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFF25C05)),
                                    ),
                                    InkWell(
                                      onTap: () => _addToCart(pId, pPrice),
                                      borderRadius: BorderRadius.circular(14),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isAdding ? const Color(0xFFF25C05) : const Color(0xFFFFF2EB),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          isAdding ? Icons.check_rounded : Icons.add_rounded,
                                          color: isAdding ? Colors.white : const Color(0xFFF25C05),
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFloatingCartBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFF25C05)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF25C05).withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _cartCount.toString(),
                    style: const TextStyle(color: Color(0xFFF25C05), fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_cartTotal.toString()} ر.ي',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Row(
            children: const [
              Text(
                'إتمام الطلب',
                style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w900),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
