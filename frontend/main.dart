import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/modern_onboarding.dart';
import 'screens/enhanced_home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/booklist_screen.dart';
import 'providers/language_provider.dart';
import 'data/services/comic_service.dart';

// Điểm khởi đầu của ứng dụng
void main() {
  runApp(const StoryVerseApp());
}

// Provider đơn giản để chia sẻ trạng thái bật/tắt chủ đề sáng/tối
class ThemeProvider extends InheritedWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  
  const ThemeProvider({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
    required super.child,
  });
  
  // Lấy ThemeProvider từ cây widget
  static ThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
  }
  
  @override
  // Khi giá trị darkMode thay đổi thì các widget con cần rebuild
  bool updateShouldNotify(ThemeProvider oldWidget) {
    return isDarkMode != oldWidget.isDarkMode;
  }
}

// Widget gốc của ứng dụng
class StoryVerseApp extends StatefulWidget {
  const StoryVerseApp({super.key});

  @override
  State<StoryVerseApp> createState() => _StoryVerseAppState();
}

class _StoryVerseAppState extends State<StoryVerseApp> {
  bool _isDarkMode = false;
  
  // Đảo trạng thái chủ đề và LƯU VÀO SharedPreferences
  void _toggleTheme() async {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
    
    // Lưu theme preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    print('💾 Saved theme preference: ${_isDarkMode ? "Dark" : "Light"}');
  }

  // Callback khi đổi ngôn ngữ để rebuild MaterialApp
  void _onLanguageChanged() {
    setState(() {
      // Rebuild toàn bộ ứng dụng khi đổi ngôn ngữ
    });
  }

  @override
  void initState() {
    super.initState();
    // Cài đặt callback để thông báo khi đổi ngôn ngữ
    LanguageManager.setOnLanguageChanged(_onLanguageChanged);
    
    // Load theme preference từ SharedPreferences
    _loadThemePreference();
  }
  
  // Load theme preference khi app khởi động
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_mode') ?? false;
    
    if (mounted) {
      setState(() {
        _isDarkMode = isDark;
      });
      print('✅ Loaded theme preference: ${isDark ? "Dark" : "Light"}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      isDarkMode: _isDarkMode,
      toggleTheme: _toggleTheme,
      child: LanguageProvider(
        currentLocale: LanguageManager.currentLocale,
        currentLanguageCode: LanguageManager.currentLanguageCode,
        changeLanguage: LanguageManager.changeLanguage,
        getLanguageName: LanguageManager.getLanguageName,
        translate: LanguageManager.translate,
        child: MaterialApp(
          title: LanguageManager.translate('app_title'),
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
          locale: LanguageManager.currentLocale,
          debugShowCheckedModeBanner: false,
          // Màn hình khởi động
          home: const SplashScreen(),
          routes: {
            // Điều hướng cơ bản
            '/onboarding': (context) => const ModernOnboardingScreen(),
            '/home': (context) => const MainNavigationScreen(),
          },
        ),
      ),
    );
  }
}

// Màn hình chứa thanh điều hướng 4 tab chính
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const EnhancedHomeScreen(),
    const ExploreScreen(),
    const BookListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final languageProvider = LanguageProvider.of(context);
    if (languageProvider == null) {
      return const Scaffold(
        body: Center(child: Text('Language provider not found')),
      );
    }
    
    final theme = Theme.of(context);
    return Scaffold(
      body: _screens[_selectedIndex],
      // Thanh điều hướng dưới cùng
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: languageProvider.translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore),
            label: languageProvider.translate('explore'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books),
            label: languageProvider.translate('book_list'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: languageProvider.translate('profile'),
          ),
        ],
      ),
    );
  }
}


// Màn hình Splash với hiệu ứng đơn giản
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward(); // Bắt đầu hiệu ứng
    
    // Kiểm tra API khi app khởi động
    _testApiOnStartup();
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ModernOnboardingScreen()),
        );
      }
    });
  }

  // Kiểm tra kết nối API cơ bản, chỉ để log
  void _testApiOnStartup() async {
    try {
      print('=== App started successfully ===');
      print('Using new API: https://cytostomal-nonsubtractive-bryanna.ngrok-free.dev/api/Comics/page');
      
      // Test API connectivity
      final isWorking = await ComicService().testApi();
      print('API test result: $isWorking');
      
      if (isWorking) {
        print('✅ New API is working correctly');
      } else {
        print('⚠️ API test failed, but app will continue with fallback data');
      }
    } catch (e) {
      print('❌ API test error: $e');
      print('App will continue with fallback data');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: AppTheme.primaryBlue,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'StoryVerse',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your Reading Adventure Starts Here',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
