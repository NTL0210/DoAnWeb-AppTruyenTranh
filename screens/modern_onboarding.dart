import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';
import '../data/services/auth_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/comic_service.dart';
import '../data/services/follow_service.dart';
import 'modern_signup_genre.dart';
import 'enhanced_home_screen.dart';
import 'forgot_password_screen.dart';
import '../widgets/border_beam_card.dart';

class ModernOnboardingScreen extends StatefulWidget {
  const ModernOnboardingScreen({super.key});

  @override
  State<ModernOnboardingScreen> createState() => _ModernOnboardingScreenState();
}

class _ModernOnboardingScreenState extends State<ModernOnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentPage = 0;

  List<OnboardingData> get _onboardingData => [
    OnboardingData(
      title: LanguageManager.translate('start_adventure'),
      description: LanguageManager.translate('discover_world'),
      illustration: Icons.menu_book,
      color: const Color(0xFF8B4513),
      gradient: const LinearGradient(
        colors: [Color(0xFF8B4513), Color(0xFFA0522D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingData(
      title: LanguageManager.translate('more_you_read'),
      description: LanguageManager.translate('rewards_description'),
      illustration: Icons.stars,
      color: const Color(0xFFD2691E),
      gradient: const LinearGradient(
        colors: [Color(0xFFD2691E), Color(0xFFCD853F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    OnboardingData(
      title: LanguageManager.translate('find_story'),
      description: LanguageManager.translate('story_description'),
      illustration: Icons.explore,
      color: const Color(0xFF654321),
      gradient: const LinearGradient(
        colors: [Color(0xFF654321), Color(0xFF8B4513)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingData[index]);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData data) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Illustration
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  gradient: data.gradient,
                  borderRadius: BorderRadius.circular(140),
                  boxShadow: [
                    BoxShadow(
                      color: data.color.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  data.illustration,
                  size: 120,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
          // Title
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                data.title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.headlineSmall?.color ?? AppTheme.textDark,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Description
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Text(
                data.description,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textTheme.bodyMedium?.color ?? AppTheme.textLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _onboardingData.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index 
                      ? AppTheme.getBrandPrimary(context) 
                      : AppTheme.getBrandPrimary(context).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Action buttons
          Column(
            children: [
              // Sign in button — gradient nền
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.heroGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppTheme.blueShadow,
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ModernSignInScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      LanguageManager.translate('sign_in'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Enter as guest button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    // Clear user data khi chọn guest mode
                    await _clearUserData();
                    
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const EnhancedHomeScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.getBrandPrimary(context), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    LanguageManager.translate('enter_as_guest'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getBrandPrimary(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Xóa user data và auth token khi chọn guest mode
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('auth_token');
      print('✅ Cleared user data for guest mode');
    } catch (e) {
      print('❌ Error clearing user data: $e');
    }
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData illustration;
  final Color color;
  final LinearGradient gradient;

  OnboardingData({
    required this.title,
    required this.description,
    required this.illustration,
    required this.color,
    required this.gradient,
  });
}

class ModernSignInScreen extends StatefulWidget {
  const ModernSignInScreen({super.key});

  @override
  State<ModernSignInScreen> createState() => _ModernSignInScreenState();
}

class _ModernSignInScreenState extends State<ModernSignInScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false; // Thêm state loading
  bool _isGoogleLoading = false; // Loading cho Google Sign-In
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '143396378619-1r2i5nr6kpjonpp7a1aqvrbb8fso7v47.apps.googleusercontent.com',  // ← Phải bắt đầu bằng 143396378619-
  );

  String _translate(String key) {
    final provider = LanguageProvider.of(context);
    return provider?.translate(key) ?? LanguageManager.translate(key);
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildSignInForm(),
                  const SizedBox(height: 24),
                  _buildSocialSignIn(),
                  const SizedBox(height: 24),
                  _buildSignUpLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo nâng cấp: heroGradient + glow shadow
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.blueShadow,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            // Tên app với ShaderMask gradient
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.heroGradient.createShader(bounds),
              child: Text(
                'StoryVerse',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white, // bị ShaderMask override
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          _translate('sign_in'),
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _translate('welcome_back'),
          style: TextStyle(
            fontSize: 15,
            color: isDark ? AppTheme.darkTextTertiary : AppTheme.textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final translate = _translate;

    return BorderBeamCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      duration: 4,
      beamSize: 0.40,
      beamColors: const [
        Colors.transparent,
        Color(0xFF60A5FA), // accentBlue
        Color(0xFFA78BFA), // accentPurple
        Colors.transparent,
      ],
      borderBaseColor: Color(0xFFE2E8F0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email or Username field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.text,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: translate('email_or_username'),
                labelStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMedium,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                hintText: translate('enter_email_or_username'),
                hintStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextTertiary : AppTheme.textLight,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.getBrandPrimary(context).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.person_outline_rounded,
                      color: AppTheme.getBrandPrimary(context), size: 18),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppTheme.dividerColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppTheme.dividerColor, width: 1.5),
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkSurface
                    : const Color(0xFFF8FAFF),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppTheme.getBrandPrimary(context), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return translate('email_or_username_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: translate('password'),
                labelStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.textMedium,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                hintText: translate('enter_password'),
                hintStyle: TextStyle(
                  color: isDark ? AppTheme.darkTextTertiary : AppTheme.textLight,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.lock_outline_rounded,
                      color: AppTheme.primaryPurple, size: 18),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: isDark
                        ? AppTheme.darkTextTertiary
                        : AppTheme.textLight,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppTheme.dividerColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: AppTheme.dividerColor, width: 1.5),
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkSurface
                    : const Color(0xFFF8FAFF),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: AppTheme.primaryPurple, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return translate('password_required');
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _showForgotPasswordDialog();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.getBrandPrimary(context),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Text(
                  translate('forgot_password'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Sign in button — gradient
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.heroGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.blueShadow,
                ),
                child: ElevatedButton(
                  onPressed: !_isLoading ? _signIn : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          LanguageManager.translate('sign_in'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialSignIn() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: theme.dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _translate('or_text'),
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color ?? AppTheme.textLight,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(child: Divider(color: theme.dividerColor)),
          ],
        ),
        const SizedBox(height: 24),
        _buildSocialButton(
          _translate('continue_with_google'),
          Icons.g_mobiledata,
          Colors.red,
          _signInWithGoogle,
        ),
      ],
    );
  }

  Widget _buildSocialButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    final bool isLoading = _isGoogleLoading;
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: color.withOpacity(0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: theme.cardColor,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    final theme = Theme.of(context);
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ModernSignUpScreen()),
          );
        },
        child: RichText(
          text: TextSpan(
            style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textLight),
            children: [
              TextSpan(text: '${_translate('dont_have_account')} '),
              TextSpan(
                text: _translate('sign_up'),
                style: TextStyle(
                  color: AppTheme.getBrandPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== Starting login process ===');
      
      final loginInput = _emailController.text.trim();
      final isEmail = loginInput.contains('@');
      
      print('🔍 Login with ${isEmail ? 'email' : 'username'}: $loginInput');
      
      final result = await AuthRepository().login(
        email: loginInput, // Backend chấp nhận cả email và username
        password: _passwordController.text,
        isUsername: !isEmail,
      );

      if (result['success'] == true) {
        print('✅ Login successful');
        
        // Lấy thông tin user từ response
        final userData = result['user'];
        final userName = userData['userName'] ?? _emailController.text.split('@')[0];
        
        // Lưu thông tin user vào SharedPreferences
        await _saveUserData(userData);
        
        // Sync follow list từ server
        final accountId = await FollowService().getAccountId();
        if (accountId != null) {
          await FollowService().syncFollowListFromServer(accountId);
        }
        
        // Preload home data trong background
        _preloadHomeData();
        
        // Hiển thị thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login successful! Welcome $userName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Chuyển đến trang chủ sau khi đăng nhập thành công
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EnhancedHomeScreen()),
          );
        }
      } else {
        print('❌ Login failed: ${result['error']}');
        
        // Hiển thị thông báo lỗi
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Login failed'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Login error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Lưu thông tin user vào SharedPreferences
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(userData));
      print('✅ User data saved to SharedPreferences');
    } catch (e) {
      print('❌ Error saving user data: $e');
    }
  }
  
  // Preload home data trong background
  void _preloadHomeData() {
    print('🚀 Starting background preload of home data...');
    // Preload comics data trong background
    ComicService().fetchComics(page: 1).then((comics) {
      print('✅ Preloaded ${comics.length} comics for home');
    }).catchError((e) {
      print('❌ Preload error: $e');
    });
    
    // Preload genres data
    ComicService().fetchGenres().then((genres) {
      print('✅ Preloaded ${genres.length} genres');
    }).catchError((e) {
      print('❌ Genres preload error: $e');
    });
  }

  void _showForgotPasswordDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  // Google Sign-In method
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });

    try {
      print('=== Starting Google Sign-In ===');
      print('📱 App Package: com.example.demo');
      print('🔑 Server Client ID: ${_googleSignIn.clientId}');
      
      // Bước 1: Sign in với Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User đã hủy sign in
        print('❌ User cancelled Google Sign-In');
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }
      
      print('✅ Google user: ${googleUser.email}');
      
      // Bước 2: Lấy authentication token từ Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      
      if (idToken == null) {
        print('❌ Failed to get Google ID token');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to retrieve Google sign-in credentials'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isGoogleLoading = false;
        });
        return;
      }
      
      print('✅ Got Google ID token');
      
      // Bước 3: Gửi idToken lên backend
      final result = await AuthRepository().googleLogin(idToken: idToken);
      
      if (result['success'] == true) {
        print('✅ Google login successful');
        
        final userData = result['user'];
        final String userName = userData['userName'] ?? '';
        
        // Lưu thông tin user
        await _saveUserData(userData);
        
        // Sync follow list từ server
        final accountId = await FollowService().getAccountId();
        if (accountId != null) {
          await FollowService().syncFollowListFromServer(accountId);
        }
        
        // Preload home data
        _preloadHomeData();
        
        // Check nếu username là username mặc định của Google (cần đổi)
        // Thường Google trả về email làm username ban đầu
        final bool needsUsername = userName.isEmpty || userName.contains('@') || userName.length < 3;
        
        if (needsUsername) {
          // Hiển thị dialog để nhập username mới
          print('⚠️ User needs to set username');
          if (mounted) {
            final String? newUsername = await _showUsernameDialog(googleUser.displayName ?? googleUser.email.split('@')[0]);
            
            if (newUsername != null && newUsername.isNotEmpty) {
              // Update username lên server
              final updateResult = await AuthService().updateUsername(newUsername);
              
              if (updateResult['success'] == true) {
                // Update userData với username mới
                userData['userName'] = newUsername;
                await _saveUserData(userData);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Welcome $newUsername! Login successful'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                print('❌ Failed to update username: ${updateResult['error']}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Unable to update username: ${updateResult['error']}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            }
          }
        } else {
          // Username đã OK
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Welcome $userName! Login successful'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        
        // Chuyển đến trang chủ
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EnhancedHomeScreen()),
          );
        }
      } else {
        print('❌ Google login failed: ${result['error']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                  content: Text(result['error'] ?? 'Google sign-in failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ Google Sign-In error: $e');
      print('📋 Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi Google Sign-In: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  // Dialog nhập username mới
  Future<String?> _showUsernameDialog(String suggestedUsername) async {
    final TextEditingController usernameController = TextEditingController(
      text: suggestedUsername,
    );
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // Bắt buộc phải nhập username
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Choose a username',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please choose your username:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter username...',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.getBrandPrimary(context), width: 2),
                  ),
                ),
                onSubmitted: (value) {
                  if (value.length >= 3) {
                    Navigator.of(context).pop(value);
                  }
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Username must have at least 3 characters',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Hủy
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final username = usernameController.text.trim();
                if (username.length >= 3) {
                  Navigator.of(context).pop(username);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Username must have at least 3 characters'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.getBrandPrimary(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
