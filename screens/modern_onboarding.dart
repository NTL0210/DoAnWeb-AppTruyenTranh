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
                      ? AppTheme.primaryBlue 
                      : AppTheme.primaryBlue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Action buttons
          Column(
            children: [
              // Sign in button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ModernSignInScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    LanguageManager.translate('sign_in'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
                    side: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    LanguageManager.translate('enter_as_guest'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppTheme.cardShadow,
              ),
              child: const Icon(
                Icons.menu_book,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'StoryVerse',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.headlineSmall?.color ?? AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Sign In',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.headlineSmall?.color ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSignInForm() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email or Username field (Backend hỗ trợ cả 2)
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.text,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: 'Email or Username',
                labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                hintText: 'Enter your email or username....',
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                prefixIcon: Icon(Icons.person_outline, color: theme.iconTheme.color),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : AppTheme.lightBlue,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email or username';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
              decoration: InputDecoration(
                labelText: LanguageManager.translate('password'),
                labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
                hintText: 'Enter your password....',
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                prefixIcon: Icon(Icons.lock_outline, color: theme.iconTheme.color),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: theme.iconTheme.color,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : AppTheme.lightBlue,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Forgot password link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _showForgotPasswordDialog();
                },
                child: const Text(
                  'forgot password?',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Sign in button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !_isLoading ? _signIn : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
                'Or',
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
          'Continue with Google',
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
              const TextSpan(text: 'Don\'t have account? '),
              TextSpan(
                text: 'Sign up',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
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
              content: Text('Đăng nhập thành công! Chào mừng $userName'),
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
              content: Text(result['error'] ?? 'Đăng nhập thất bại'),
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
            content: Text('Lỗi: $e'),
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
              content: Text('Không thể lấy thông tin đăng nhập từ Google'),
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
                      content: Text('Chào mừng $newUsername! Đăng nhập thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                print('❌ Failed to update username: ${updateResult['error']}');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Không thể cập nhật username: ${updateResult['error']}'),
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
                content: Text('Chào mừng $userName! Đăng nhập thành công'),
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
              content: Text(result['error'] ?? 'Đăng nhập Google thất bại'),
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
            'Chọn tên người dùng',
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
                'Vui lòng chọn tên người dùng của bạn:',
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
                  hintText: 'Nhập username...',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
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
                'Username phải có ít nhất 3 ký tự',
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
                'Hủy',
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
                      content: Text('Username phải có ít nhất 3 ký tự'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Xác nhận',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
