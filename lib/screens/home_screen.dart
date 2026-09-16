import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// ============================================================
///  نقطة تشغيل تجريبية للمعاينة المستقلة (يمكن حذفها عند الدمج
///  مع بقية شاشات التطبيق).
/// ============================================================
void main() {
  runApp(const SpeedGoApp());
}

class SpeedGoApp extends StatelessWidget {
  const SpeedGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Speed Go',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.bgLight,
        fontFamily: GoogleFonts.tajawal().fontFamily,
        useMaterial3: true,
      ),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      home: const HomePage(),
    );
  }
}

/// ============================================================
///  الألوان — مطابقة تماماً لمتغيرات :root في ملف CSS الأصلي
/// ============================================================
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

/// تدرجات الأقسام (category-item:nth-child(10n+1) ... (10n+0))
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

/// ============================================================
///  نماذج البيانات
///  ⚠️ placeholder مؤقت — سيتم استبداله ببيانات home.js الحقيقية
///  (يبدو أنها تُجلب من Supabase) عند إرسال ذلك الملف.
/// ============================================================
class CategoryModel {
  final String name;
  final IconData icon;
  const CategoryModel(this.name, this.icon);
}

class StoreModel {
  final String name;
  final String tags;
  final double rating;
  final String time;
  final String deliveryFee;
  final String imageUrl;
  const StoreModel({
    required this.name,
    required this.tags,
    required this.rating,
    required this.time,
    required this.deliveryFee,
    required this.imageUrl,
  });
}

final List<CategoryModel> kPlaceholderCategories = [
  CategoryModel('مطاعم', FontAwesomeIcons.utensils),
  CategoryModel('سوبرماركت', FontAwesomeIcons.cartShopping),
  CategoryModel('صيدليات', FontAwesomeIcons.prescriptionBottleMedical),
  CategoryModel('حلويات', FontAwesomeIcons.iceCream),
  CategoryModel('مخابز', FontAwesomeIcons.breadSlice),
  CategoryModel('مشروبات', FontAwesomeIcons.mugSaucer),
  CategoryModel('لحوم', FontAwesomeIcons.drumstickBite),
  CategoryModel('إلكترونيات', FontAwesomeIcons.mobileScreen),
  CategoryModel('هدايا', FontAwesomeIcons.gift),
];

final List<StoreModel> kPlaceholderStores = [
  StoreModel(
    name: 'مطعم البيت الشامي',
    tags: 'مأكولات شامية • مشاوي',
    rating: 4.8,
    time: '25-35 د',
    deliveryFee: '500 ر.ي',
    imageUrl:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=200',
  ),
  StoreModel(
    name: 'سوبرماركت الوفاء',
    tags: 'بقالة • منتجات منزلية',
    rating: 4.6,
    time: '15-25 د',
    deliveryFee: 'مجاني',
    imageUrl:
        'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=200',
  ),
  StoreModel(
    name: 'صيدلية الشفاء',
    tags: 'أدوية • مستلزمات طبية',
    rating: 4.9,
    time: '10-20 د',
    deliveryFee: '300 ر.ي',
    imageUrl:
        'https://images.unsplash.com/photo-1576602976047-174e57a47881?w=200',
  ),
];

/// ============================================================
///  الصفحة الرئيسية
/// ============================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  int? _shakingIndex;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // مطابق لمدة shakeOneSecond
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake(int index) {
    setState(() => _shakingIndex = index);
    _shakeController.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _shakingIndex = null);
    });
  }

  // ---- محاكاة CSS @keyframes shakeOneSecond بدقّة نسب الوقت نفسها ----
  double _interpolateKeyframes(
      double t, List<double> times, List<double> values) {
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
        const [1.0, 1.05, 1.05, 1.05, 1.05, 1.05, 1.05, 1.0],
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBannersSlider(),
                      _buildSectionTitle('أقسام Speed Go',
                          actionLabel: 'عرض الكل'),
                      _buildCategoriesGrid(),
                      _buildSectionTitle('المتاجر المتاحة بالقرب منك'),
                      _buildStoresList(),
                    ],
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

  // ---------------- الهيدر ----------------
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(FontAwesomeIcons.locationDot,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('التوصيل إلى',
                        style: _tajawal(
                            size: 12,
                            weight: FontWeight.w500,
                            color: AppColors.textGray)),
                    Row(
                      children: [
                        Text('عدن - خورمكسر',
                            style: _tajawal(size: 15, weight: FontWeight.w800)),
                        const SizedBox(width: 3),
                        const Icon(FontAwesomeIcons.chevronDown,
                            size: 10, color: AppColors.textDark),
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
                  const Icon(FontAwesomeIcons.bell,
                      size: 18, color: AppColors.textDark),
                  Positioned(
                    top: 5,
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

  // ---------------- شريط البحث ----------------
  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
      child: TextField(
        style: _tajawal(size: 14, weight: FontWeight.w400),
        decoration: InputDecoration(
          hintText: 'ابحث عن مطعم، سوبرماركت، صيدلية...',
          hintStyle:
              _tajawal(size: 14, weight: FontWeight.w400, color: AppColors.textGray),
          filled: true,
          fillColor: AppColors.searchBg,
          // في CSS الأيقونة على اليمين (right:18px)؛ لأن الاتجاه RTL فإن
          // "بداية" الحقل (prefixIcon) هي فعلياً اليمين هنا.
          prefixIcon: const Padding(
            padding: EdgeInsets.only(right: 18, left: 10),
            child: Icon(FontAwesomeIcons.magnifyingGlass,
                size: 16, color: AppColors.textGray),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
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

  // ---------------- بانرات العروض ----------------
  Widget _buildBannersSlider() {
    final banners = [
      _BannerData(
        gradient: const [Color(0xFFFF6B35), Color(0xFFF25C05)],
        icon: FontAwesomeIcons.bolt,
        title: 'عرض Speed Go الخاطف!',
        subtitle: 'توصيل مجاني لجميع طلبات السوبرماركت اليوم',
        buttonLabel: 'اطلب الآن',
      ),
      _BannerData(
        gradient: const [Color(0xFF00B4D8), Color(0xFF0077B6)],
        icon: FontAwesomeIcons.prescriptionBottleMedical,
        title: 'صحتك تهمنا',
        subtitle: 'اطلب أدويتك ومستلزماتك من أقرب صيدلية بلحظات',
        buttonLabel: 'تصفح الصيدليات',
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
            padding:
                EdgeInsets.only(left: index == banners.length - 1 ? 0 : 15),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              child: _buildBannerCard(b),
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
        // يطابق linear-gradient(135deg, ...) في CSS
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
              Text(b.title,
                  style: _tajawal(
                      size: 18, weight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 5),
              Text(
                b.subtitle,
                style: _tajawal(
                    size: 13,
                    weight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(b.buttonLabel,
                    style: _tajawal(size: 11, weight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- عنوان القسم ----------------
  Widget _buildSectionTitle(String title, {String? actionLabel}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: _tajawal(size: 17, weight: FontWeight.w800)),
          if (actionLabel != null)
            GestureDetector(
              onTap: () {},
              child: Text(actionLabel,
                  style: _tajawal(
                      size: 13, weight: FontWeight.w700, color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  // ---------------- شبكة الأقسام ----------------
  Widget _buildCategoriesGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 15),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: kPlaceholderCategories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 145,
        ),
        itemBuilder: (context, index) {
          final cat = kPlaceholderCategories[index];
          final gradient = kCategoryGradients[index % kCategoryGradients.length];
          return GestureDetector(
            onTap: () => _triggerShake(index),
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
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(cat.icon, size: 40, color: Colors.white),
                    const SizedBox(height: 10),
                    Text(cat.name,
                        style: _tajawal(
                            size: 12, weight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- قائمة المتاجر ----------------
  Widget _buildStoresList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: kPlaceholderStores
            .map((store) => Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: _buildStoreCard(store),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildStoreCard(StoreModel store) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFDFDFD)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                image: DecorationImage(
                    image: NetworkImage(store.imageUrl), fit: BoxFit.cover),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(store.name, style: _tajawal(size: 16, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(store.tags,
                      style: _tajawal(
                          size: 12, weight: FontWeight.w500, color: AppColors.textGray)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _metaItem(FontAwesomeIcons.star, AppColors.ratingStar,
                          store.rating.toString()),
                      const SizedBox(width: 12),
                      _metaItem(FontAwesomeIcons.clock, AppColors.timeIcon, store.time),
                      const SizedBox(width: 12),
                      _metaItem(FontAwesomeIcons.motorcycle, AppColors.deliveryIcon,
                          store.deliveryFee),
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
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: _tajawal(size: 12, weight: FontWeight.w700, color: AppColors.textDark)),
      ],
    );
  }

  // ---------------- شريط التنقل السفلي ----------------
  Widget _buildBottomNav() {
    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(icon: FontAwesomeIcons.house, label: 'الرئيسية', active: true, onTap: () {}),
          _navItem(
              icon: FontAwesomeIcons.clipboardList,
              label: 'طلباتي',
              active: false,
              onTap: () {}),
          _navItem(
            icon: FontAwesomeIcons.bagShopping,
            label: 'السلة',
            active: false,
            badgeCount: 2,
            onTap: () {},
          ),
          _navItem(icon: FontAwesomeIcons.user, label: 'حسابي', active: false, onTap: () {}),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
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
                Icon(icon, size: 20, color: color),
                if (badgeCount != null)
                  Positioned(
                    top: -5,
                    right: -12,
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: _tajawal(size: 9, weight: FontWeight.w800, color: Colors.white),
                      ),
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
  const _BannerData({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
  });
}
