import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import 'package:speedgo_client/screens/store_screen.dart';

class HomeScreen extends StatefulWidget {
  final SupabaseClient supabase;
  const HomeScreen({super.key, required this.supabase});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _filteredStores = [];
  bool _isLoadingCategories = true;
  bool _isLoadingStores = true;
  String? _errorMessage;
  String _activeCategoryFilter = 'الكل';
  final TextEditingController _searchController = TextEditingController();

  final List<List<Color>> _categoryGradients = [
    [const Color(0xFFFF9F1C), const Color(0xFFF25C05)],
    [const Color(0xFFFF7EB3), const Color(0xFFFF758C)],
    [const Color(0xFF52B788), const Color(0xFF2D6A4F)],
    [const Color(0xFF48CAE4), const Color(0xFF0077B6)],
    [const Color(0xFFB5179E), const Color(0xFF7209B7)],
    [const Color(0xFF439A86), const Color(0xFF00725B)],
    [const Color(0xFFD4A373), const Color(0xFFA98467)],
    [const Color(0xFF8D99AE), const Color(0xFF2B2D42)],
    [const Color(0xFFE07A5F), const Color(0xFF3D405B)],
    [const Color(0xFFF4A261), const Color(0xFFE76F51)],
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchCategories(),
      _fetchStores(),
    ]);
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await widget.supabase
          .from('categories')
          .select()
          .order('sort_order', ascending: true);

      if (mounted) {
        setState(() {
          _categories = (res as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _fetchStores() async {
    try {
      final res = await widget.supabase.from('stores').select();

      if (mounted) {
        final list = (res as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        setState(() {
          _stores = list;
          _applyFilters();
          _isLoadingStores = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingStores = false;
        });
      }
    }
  }

  void _applyFilters() {
    final cleanSearch = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredStores = _stores.where((s) {
        final name = (s['name'] ?? s['store_name'] ?? '').toString().toLowerCase();
        final cat = (s['category'] ?? '').toString().toLowerCase();

        final matchesCategory = _activeCategoryFilter == 'الكل' ||
            cat.contains(_activeCategoryFilter.toLowerCase());
        final matchesSearch = cleanSearch.isEmpty ||
            name.contains(cleanSearch) ||
            cat.contains(cleanSearch);

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onSelectCategory(String catName) {
    setState(() {
      _activeCategoryFilter = (_activeCategoryFilter == catName) ? 'الكل' : catName;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Theme(
        data: ThemeData(
          textTheme: GoogleFonts.tajawalTextTheme(),
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(),
                    _buildSearchSection(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchData,
                        color: const Color(0xFFF25C05),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.only(bottom: 95),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBannersSlider(),
                              _buildSectionHeader(
                                'أقسام Speed Go',
                                showViewAll: true,
                                onViewAll: () => _onSelectCategory('الكل'),
                              ),
                              _buildCategoriesGrid(),
                              _buildSectionHeader(
                                _activeCategoryFilter == 'الكل'
                                    ? 'المتاجر المتاحة بالقرب منك'
                                    : 'متاجر قسم ($_activeCategoryFilter)',
                              ),
                              _buildStoresList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomNav(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ستفتح خريطة تحديد موقع التوصيل في التحديث القادم!')),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2EB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.location_on, color: Color(0xFFF25C05), size: 24),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('التوصيل إلى', style: TextStyle(fontSize: 13, color: Color(0xFF757575), fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Text('عدن - خورمكسر', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF1A1A1A)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('لا توجد إشعارات جديدة حالياً، طلباتك كلها تمام!')),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEFEFEF)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_rounded, color: Color(0xFF1A1A1A), size: 24),
                  Positioned(
                    top: 11,
                    left: 11,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE63946),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => _applyFilters(),
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
          decoration: const InputDecoration(
            hintText: 'ابحث عن مطعم، سوبرماركت، صيدلية...',
            hintStyle: TextStyle(fontSize: 14, color: Color(0xFF757575), fontWeight: FontWeight.w500),
            prefixIcon: Icon(Icons.search, color: Color(0xFF757575), size: 22),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildBannersSlider() {
    final banners = [
      {
        'title': 'عرض Speed Go الخاطف!',
        'subtitle': 'توصيل مجاني لجميع طلبات السوبرماركت اليوم',
        'btn': 'اطلب الآن',
        'colors': [const Color(0xFFFF6B35), const Color(0xFFF25C05)],
        'icon': Icons.bolt_rounded,
        'cat': 'سوبر ماركت',
      },
      {
        'title': 'صحتك تهمنا',
        'subtitle': 'اطلب أدويتك ومستلزماتك من أقرب صيدلية بلحظات',
        'btn': 'تصفح الصيدليات',
        'colors': [const Color(0xFF00B4D8), const Color(0xFF0077B6)],
        'icon': Icons.medical_services_rounded,
        'cat': 'صيدليات',
      },
    ];

    return SizedBox(
      height: 150,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: banners.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final b = banners[index];
          return InkWell(
            onTap: () => _onSelectCategory(b['cat'] as String),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: b['colors'] as List<Color>,
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -20,
                    child: Icon(
                      b['icon'] as IconData,
                      size: 130,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          b['title'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          b['subtitle'] as String,
                          style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            b['btn'] as String,
                            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showViewAll = false, VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
          if (showViewAll)
            GestureDetector(
              onTap: onViewAll,
              child: const Text('عرض الكل', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFF25C05))),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    if (_isLoadingCategories) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Color(0xFFF25C05)),
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _errorMessage ?? 'لا توجد أقسام متوفرة',
            style: const TextStyle(color: Color(0xFF757575), fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        mainAxisExtent: 148,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final name = (cat['name'] ?? '').toString().trim();
        final img = (cat['image_url'] ?? '').toString();
        final gradient = _categoryGradients[index % _categoryGradients.length];

        return CategoryItemCard(
          name: name,
          imageUrl: img,
          gradient: gradient,
          onTap: () => _onSelectCategory(name),
        );
      },
    );
  }

  Widget _buildStoresList() {
    if (_isLoadingStores) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFFF25C05)),
              SizedBox(height: 10),
              Text('جاري جلب المتاجر...', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF757575))),
            ],
          ),
        ),
      );
    }

    if (_filteredStores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              const Icon(Icons.store_mall_directory_outlined, size: 50, color: Color(0xFFBDBDBD)),
              const SizedBox(height: 10),
              Text(
                _activeCategoryFilter == 'الكل'
                    ? 'لا توجد متاجر مطابقة حالياً!'
                    : 'لا توجد متاجر في قسم ($_activeCategoryFilter) حالياً',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF757575)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _filteredStores.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final store = _filteredStores[index];
        final name = store['name'] ?? store['store_name'] ?? 'متجر غير مسمى';
        final cat = store['category'] ?? 'عام';
        final img = store['logo_url'] ?? 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?auto=format&fit=crop&w=200&q=80';

        return InkWell(
          onTap: () {
            final storeId = store['id']?.toString() ?? '';
            if (storeId.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoreScreen(
                    supabase: widget.supabase,
                    storeId: storeId,
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: const Color(0xFFFDFDFD)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 90,
                    height: 90,
                    color: const Color(0xFFF5F5F5),
                    child: Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.store, color: Color(0xFFBDBDBD), size: 38),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cat,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF757575), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFB300)),
                          SizedBox(width: 3),
                          Text('4.5', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                          SizedBox(width: 12),
                          Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF5C677D)),
                          SizedBox(width: 3),
                          Text('30 دقيقة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                          SizedBox(width: 12),
                          Icon(Icons.delivery_dining_rounded, size: 18, color: Color(0xFF2A9D8F)),
                          SizedBox(width: 3),
                          Text('سريع', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEFEFEF))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'الرئيسية'),
          _buildNavItem(1, Icons.assignment_outlined, 'طلباتي'),
          _buildNavItem(2, Icons.shopping_bag_outlined, 'السلة', badge: '2'),
          _buildNavItem(3, Icons.person_outline_rounded, 'حسابي'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {String? badge}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? const Color(0xFFF25C05) : const Color(0xFF757575),
              ),
              if (badge != null)
                Positioned(
                  top: -5,
                  left: -8,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF25C05),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        badge,
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              color: isSelected ? const Color(0xFFF25C05) : const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItemCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final List<Color> gradient;
  final VoidCallback onTap;

  const CategoryItemCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<CategoryItemCard> createState() => _CategoryItemCardState();
}

class _CategoryItemCardState extends State<CategoryItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0.0).then((_) {
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final val = _shakeAnimation.value;
        final rotation = val == 0 ? 0.0 : sin(val * pi * 8) * 0.08;
        final scale = val == 0 ? 1.0 : 1.0 + (sin(val * pi * 4).abs() * 0.05);

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: rotation,
            child: GestureDetector(
              onTap: _triggerShake,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.imageUrl.isNotEmpty)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            widget.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFDFD),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
