import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase/supabase.dart';

// تعريف عميل Supabase العام
late final SupabaseClient supabase;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Supabase مباشرة
  supabase = SupabaseClient(
    'https://ldefaxirgruqulxhkaqh.supabase.co',
    'sb_publishable_Gsn2xn5DjAJehY0SGFubzw_KxV-hG-4',
  );

  runApp(const SpeedGoApp());
}

class SpeedGoApp extends StatelessWidget {
  const SpeedGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speed Go',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'AE'),
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const MainAuthWrapper(),
    );
  }
}

class MainAuthWrapper extends StatefulWidget {
  const MainAuthWrapper({super.key});

  @override
  State<MainAuthWrapper> createState() => _MainAuthWrapperState();
}

class _MainAuthWrapperState extends State<MainAuthWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  void _checkExistingSession() {
    final session = supabase.auth.currentSession;
    if (session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToHome();
      });
    }
  }

  void _navigateToHome() {
    // سيتم التوجيه لصفحة home.dart فور إنشائها
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. خلفية واجهة تسجيل الدخول مع طبقة التعتيم
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=1080&q=80',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(15, 23, 42, 0.7),
                    Color.fromRGBO(15, 23, 42, 0.95),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. واجهة تسجيل الدخول (بطاقة الزجاج Frosted Glass)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: const AuthCard(),
            ),
          ),

          // 3. شاشة البداية الافتتاحية (Splash Screen) مع حركة التلاشي
          if (_showSplash)
            AnimatedOpacity(
              opacity: _showSplash ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: SplashScreenOverlay(
                onStartPressed: () {
                  setState(() {
                    _showSplash = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// شاشة البداية (Splash Screen Overlay)
// ==========================================
class SplashScreenOverlay extends StatefulWidget {
  final VoidCallback onStartPressed;
  const SplashScreenOverlay({super.key, required this.onStartPressed});

  @override
  State<SplashScreenOverlay> createState() => _SplashScreenOverlayState();
}

class _SplashScreenOverlayState extends State<SplashScreenOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _sloganFadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );

    _sloganFadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF050505), Color(0xFF151515), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF25C05).withOpacity(0.35),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.electric_bolt_rounded,
                    size: 110,
                    color: Color(0xFFF25C05),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _sloganFadeAnimation,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFFF25C05)],
                ).createShader(bounds),
                child: const Text(
                  'معنا طلبك أسرع',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
            FadeTransition(
              opacity: _sloganFadeAnimation,
              child: InkWell(
                onTap: widget.onStartPressed,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B35), Color(0xFFF25C05)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF25C05).withOpacity(0.4),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'ابدأ الآن',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// بطاقة تسجيل الدخول والتسجيل (Auth Card)
// ==========================================
class AuthCard extends StatefulWidget {
  const AuthCard({super.key});

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && name.isEmpty)) {
      setState(() {
        _errorMessage = 'يرجى تعبئة جميع الحقول.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': name},
        );
      }
      // التوجيه لصفحة home عند اكتمال الربط
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ: تأكد من صحة البيانات.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 50,
                offset: const Offset(0, 25),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الشعار
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF25C05).withOpacity(0.3),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.electric_bolt_rounded, size: 55, color: Color(0xFFF25C05)),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Speed Go',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'معنا طلبك أسرع',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 25),

              // أزرار التبديل (Tabs)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'تسجيل الدخول',
                              style: TextStyle(
                                color: _isLogin ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isLogin ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'حساب جديد',
                              style: TextStyle(
                                color: !_isLogin ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // حقول الإدخال
              if (!_isLogin) ...[
                _buildInputField(
                  controller: _nameController,
                  hintText: 'اسمك الكريم',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
              ],

              _buildInputField(
                controller: _emailController,
                hintText: 'البريد الإلكتروني',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              _buildInputField(
                controller: _passwordController,
                hintText: 'كلمة المرور',
                icon: Icons.lock_outline_rounded,
                obscureText: true,
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],

              const SizedBox(height: 18),

              // زر الدخول / التسجيل الرئيسي
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF25C05),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
                    shadowColor: const Color(0xFFF25C05).withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isLogin ? 'دخول' : 'إنشاء حساب',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // الخط الفاصل
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.1))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('أو', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.1))),
                ],
              ),

              const SizedBox(height: 18),

              // زر الدخول كزائر
              InkWell(
                onTap: () {
                  // الانتقال المباشر لصفحة home كزائر
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'تصفح التطبيق كزائر',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_back, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
