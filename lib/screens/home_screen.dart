import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';
import 'package:speedgo_client/screens/store_screen.dart';
import 'package:speedgo_client/screens/category_stores_screen.dart';

class AppColors {
  static const Color primary = Color(0xFFF25C05);
  static const Color primaryLight = Color(0xFFFFF2EB);
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textGray = Color(0xFF757575);
  static const Color border = Color(0xFFEFEFEF);
  static const Color searchBg = Color(0xFFF6F6F6);
  static const Color searchBorder = Color(0xFFF0F0F0);
  static const Color badgeRed = Color(0xFFE63946);
  static const Color ratingStar = Color(0xFFFFB300);
  static const Color timeIcon = Color(0xFF5C677D);
  static const Color deliveryIcon = Color(0xFF2A9D8F);
}

const List<List<Color>> kCategoryGradients = [
  [Color(0xFFFF9F1C), Color(0xFFF25C05)],
  [Color(0xFFFF7EB3), Color(0xFFFF758C)],
  [Color(0xFF52B788), Color(0xFF2D6A4F)],
  [Color(0xFF48CAE4), Color(0xFF0077B6)],
  [Color(0xFFB5179E), Color(0xFF7209B7)],
  [Color(0xFF439A86), Color(0xFF00725B)],
  [Color(0xFFD4A373), Color(0xFFA98467)],
  [Color(0xFF8D99AE), Color(0xFF2B2D42)],
  [Color(0xFFE07A5F), Color(0xFF3D405B)],
  [Color(0xFFF4A261), Color(0xFFE76F51)],
];

class HomeScreen extends StatefulWidget {
  final SupabaseClient supabase;
  const HomeScreen({super.key, required this.supabase});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  int? _shakingIndex;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _stores = [];
  List<Map<String, dynamic>> _filteredStores = [];

  bool _isLoadingCategories = true;
  bool _isLoadingStores = true;
  String _activeCategoryFilter = 'الكل';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fetchData();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _searchController.dispose();
    super.dispose();
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
      if (mounted) setState(() => _isLoadingCategories = false);
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
      if (mounted) setState(() => _isLoadingStores = false);
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

  void _triggerShake(int index, String categoryName, String categoryImg, List<Color> gradient) {
    setState(() => _shakingIndex = index);
    _shakeController.forward(from: 0).whenComplete(() {
      if (mounted) {
        setState(() => _shakingIndex = null);
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 450),
            pageBuilder: (_, animation, __) => FadeTransition(
              opacity: animation,
              child: CategoryStoresScreen(
                supabase: widget.supabase,
                categoryName: categoryName,
                categoryImage: categoryImg,
                gradientColors: gradient,
              ),
            ),
          ),
        );
      }
    });
  }

  double _interpolateKeyframes(double t, List<double> times, List<double> values) {
    for (int i = 0; i < times.length - 1; i++) {
      if (t >= times[i] && t <= times[i + 1]) {
        final localT = (t - times[i]) / (times[i + 1] - times[i]);
        return values[i] + (values[i + 1] - values[i]) * localT;
      }
    }
    return values.last;
  }

  double _shakeRotationDeg(double t) => _interpolateKeyframes(
        t,
        const [0.0, 0.15, 0.30, 0.45, 0.60, 0.75, 0.90, 1.0],
        const [0.0, -8.0, 8.0, -8.0, 8.0, -8.0, 8.0, 0.0],
      );

  double _shakeScale(double t) => _interpolateKeyframes(
        t,
        const [0.0, 0.15, 0.30, 0.45, 0.60, 0.75, 0.90, 1.0],
        const [1.0, 1.15, 1.25, 1.35, 1.45, 1.55, 1.65, 1.8],
      );

  TextStyle _tajawal({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textDark,
  }) {
    return GoogleFonts.tajawal(fontSize: size, fontWeight: weight, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgLight,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchSection(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetchData,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBannersSlider(),
                        _buildSectionTitle(
                          'أقسام Speed Go',
                          actionLabel: 'عرض الكل',
                          onActionTap: () {
                            setState(() {
                              _activeCategoryFilter = 'الكل';
                              _applyFilters();
                            });
                          },
                        ),
                        _buildCategoriesGrid(),
                        _buildSectionTitle(
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
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ستفتح خريطة تحديد موقع التوصيل في التحديث القادم!')),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('التوصيل إلى', style: _tajawal(size: 12, weight: FontWeight.w500, color: AppColors.textGray)),
                    Row(
                      children: [
                        Text('عدن - خورمكسر', style: _tajawal(size: 15, weight: FontWeight.w800)),
                        const SizedBox(width: 3),
                        const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textDark),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 20, color: AppColors.textDark),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.badgeRed,
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
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _applyFilters(),
        style: _tajawal(size: 14, weight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'ابحث عن مطعم، سوبرماركت، صيدلية...',
          hintStyle: _tajawal(size: 14, weight: FontWeight.w400, color: AppColors.textGray),
          filled: true,
          fillColor: AppColors.searchBg,
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textGray),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.searchBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.searchBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildBannersSlider() {
    final banners = [
      _BannerData(
        gradient: const [Color(0xFFFF6B35), Color(0xFFF25C05)],
        icon: Icons.bolt_rounded,
        title: 'عرض Speed Go الخاطف!',
        subtitle: 'توصيل مجاني لجميع طلبات السوبرماركت اليوم',
        buttonLabel: 'اطلب الآن',
        category: 'سوبر ماركت',
      ),
      _BannerData(
        gradient: const [Color(0xFF00B4D8), Color(0xFF0077B6)],
        icon: Icons.medical_services_rounded,
        title: 'صحتك تهمنا',
        subtitle: 'اطلب أدويتك ومستلزماتك من أقرب صيدلية بلحظات',
        buttonLabel: 'تصفح الصيدليات',
        category: 'صيدليات',
      ),
    ];
    return SizedBox(
      height: 140,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: banners.length,
        itemBuilder: (context, index) {
          final b = banners[index];
          return Padding(
            padding: EdgeInsets.only(left: index == banners.length - 1 ? 0 : 15),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeCategoryFilter = b.category;
                  _applyFilters();
                });
              },
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: _buildBannerCard(b),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerCard(_BannerData b) {
    return Container(
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: b.gradient,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -10,
            bottom: -20,
            child: Icon(b.icon, size: 110, color: Colors.white.withOpacity(0.15)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(b.title, style: _tajawal(size: 18, weight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 5),
              Text(b.subtitle, style: _tajawal(size: 13, weight: FontWeight.w500, color: Colors.white.withOpacity(0.9))),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Text(b.buttonLabel, style: _tajawal(size: 11, weight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? actionLabel, VoidCallback? onActionTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: _tajawal(size: 17, weight: FontWeight.w800)),
          if (actionLabel != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(actionLabel, style: _tajawal(size: 13, weight: FontWeight.w700, color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    if (_isLoadingCategories) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_categories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 15),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 145,
        ),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final name = (cat['name'] ?? '').toString().trim();
          final imgUrl = (cat['image_url'] ?? '').toString();
          final gradient = kCategoryGradients[index % kCategoryGradients.length];

          return GestureDetector(
            onTap: () => _triggerShake(index, name, imgUrl, gradient),
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final active = _shakingIndex == index;
                final t = active ? _shakeController.value : 0.0;
                final deg = active ? _shakeRotationDeg(t) : 0.0;
                final scale = active ? _shakeScale(t) : 1.0;
                return Transform.rotate(
                  angle: deg * 3.1415926535 / 180,
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (imgUrl.isNotEmpty)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox()),
                        ),
                      ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))]),
                        child: Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: _tajawal(size: 12, weight: FontWeight.w800, color: AppColors.textDark)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoresList() {
    if (_isLoadingStores) {
      return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_filteredStores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              const Icon(Icons.store_mall_directory_outlined, size: 40, color: AppColors.textGray),
              const SizedBox(height: 10),
              Text('لا توجد متاجر مطابقة حالياً!', style: _tajawal(size: 14, weight: FontWeight.w700, color: AppColors.textGray)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _filteredStores.map((store) => Padding(padding: const EdgeInsets.only(bottom: 15), child: _buildStoreCard(store))).toList(),
      ),
    );
  }

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final storeId = store['id']?.toString() ?? '';
    final name = store['name'] ?? store['store_name'] ?? 'متجر غير مسمى';
    final tags = store['category'] ?? 'عام';
    final imageUrl = store['logo_url'] ?? 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=200';

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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFDFDFD)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8))]),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name, style: _tajawal(size: 16, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(tags, style: _tajawal(size: 12, weight: FontWeight.w500, color: AppColors.textGray)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _metaItem(Icons.star_rounded, AppColors.ratingStar, '4.8'),
                      const SizedBox(width: 12),
                      _metaItem(Icons.access_time_filled_rounded, AppColors.timeIcon, '25-35 د'),
                      const SizedBox(width: 12),
                      _metaItem(Icons.delivery_dining_rounded, AppColors.deliveryIcon, 'سريع'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaItem(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: _tajawal(size: 12, weight: FontWeight.w700, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 75,
      decoration: BoxDecoration(color: Colors.white, border: const Border(top: BorderSide(color: AppColors.border)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -4))]),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(icon: Icons.home_rounded, label: 'الرئيسية', active: true, onTap: () {}),
          _navItem(icon: Icons.assignment_outlined, label: 'طلباتي', active: false, onTap: () {}),
          _navItem(icon: Icons.shopping_bag_outlined, label: 'السلة', active: false, badgeCount: 2, onTap: () {}),
          _navItem(icon: Icons.person_outline_rounded, label: 'حسابي', active: false, onTap: () {}),
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required String label, required bool active, required VoidCallback onTap, int? badgeCount}) {
    final color = active ? AppColors.primary : AppColors.textGray;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: color),
                if (badgeCount != null)
                  Positioned(
                    top: -5,
                    right: -12,
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: Text('$badgeCount', style: _tajawal(size: 9, weight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(label, style: _tajawal(size: 11, weight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

class _BannerData {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final String category;

  const _BannerData({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.category,
  });
}
