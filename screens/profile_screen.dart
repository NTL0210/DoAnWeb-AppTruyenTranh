import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../theme/app_theme.dart';
import '../main.dart';
import '../providers/language_provider.dart';
import '../data/services/auth_service.dart';
import '../data/repositories/auth_repository.dart';
import '../data/services/avatar_service.dart';
import 'enhanced_home_screen.dart';
import 'explore_screen.dart';
import 'booklist_screen.dart';
import 'modern_onboarding.dart';
import '../widgets/common_bottom_nav.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  int _selectedIndex = 3; // Profile is index 3
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // User login state
  bool _isLoggedIn = false; // Mặc định là guest (false)
  String _userName = 'Guest User';
  String _userEmail = 'Guest Account';
  String? _userImage;
  Map<String, dynamic>? _userData; // Thông tin user từ API
  bool _notificationsEnabled = true;
  bool _readingReminders = true;
  String _selectedFontSize = 'Medium';
  
  // Avatar upload state
  bool _isUploadingAvatar = false;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Add a small helper to bust NetworkImage cache by appending a timestamp query
  String _cacheBustUrl(String url) {
    try {
      final String absoluteUrl = url.startsWith('/')
          ? '${AuthService.baseUrl}$url'
          : url;
      final uri = Uri.parse(absoluteUrl);
      final Map<String, String> params = Map<String, String>.from(uri.queryParameters);
      params['v'] = DateTime.now().millisecondsSinceEpoch.toString();
      return uri.replace(queryParameters: params).toString();
    } catch (_) {
      return url;
    }
  }

  String? _buildApiUploadsFallback(String absoluteUrl) {
    try {
      final uri = Uri.parse(absoluteUrl);
      if ((uri.path.startsWith('/uploads/') || uri.path.startsWith('/uploads/')) &&
          !uri.path.startsWith('/api/')) {
        final fallbackPath = '/api${uri.path}';
        return uri.replace(path: fallbackPath).toString();
      }
    } catch (_) {}
    return null;
  }

  Map<String, String?> _resolveAvatarUrls(String src) {
    if (src.startsWith('http')) {
      final primary = _cacheBustUrl(src);
      final fallback = _buildApiUploadsFallback(primary);
      return {
        'primary': primary,
        'fallback': fallback != null ? _cacheBustUrl(fallback) : null,
      };
    }

    if (src.startsWith('/')) {
      final primary = _cacheBustUrl('${AuthService.baseUrl}$src');
      final bool isUploadsPath =
          src.startsWith('/uploads/') || src.startsWith('/uploads/');
      final fallback = isUploadsPath
          ? _cacheBustUrl('${AuthService.baseUrl}/api$src')
          : null;
      return {
        'primary': primary,
        'fallback': fallback,
      };
    }

    return {'primary': src, 'fallback': null};
  }

  Widget _buildNetworkAvatarWithFallback({
    required String primaryUrl,
    String? fallbackUrl,
    required Widget placeholder,
  }) {
    return Image.network(
      primaryUrl,
      width: 96,
      height: 96,
      fit: BoxFit.cover,
      headers: {
        'Cache-Control': 'no-cache',
        'ngrok-skip-browser-warning': 'true',
        'User-Agent': 'demo-app/1.0 (flutter)',
      },
      errorBuilder: (context, error, stackTrace) {
        if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
          return Image.network(
            fallbackUrl,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            headers: {
              'Cache-Control': 'no-cache',
              'ngrok-skip-browser-warning': 'true',
              'User-Agent': 'demo-app/1.0 (flutter)',
            },
            errorBuilder: (context, error, stackTrace) {
              print('❌ Avatar fallback failed: $error');
              return placeholder;
            },
          );
        }
        print('❌ Avatar load failed: $error');
        return placeholder;
      },
    );
  }
  
  // Refresh profile from server after updating avatar/username
  Future<void> _refreshProfileFromServer() async {
    try {
      final profileData = await AuthService().fetchUserProfile();
      if (!mounted || profileData == null) return;
      String? image = profileData['image'];
      String? finalImageUrl;
      if (image != null && image.isNotEmpty) {
        if (image.startsWith('data:image/')) {
          finalImageUrl = image; // base64
        } else if (image.startsWith('http') || image.startsWith('/')) {
          finalImageUrl = _cacheBustUrl(image);
        } else {
          finalImageUrl = image;
        }
      }
      setState(() {
        if (profileData['userName'] != null && (profileData['userName'] as String).isNotEmpty) {
          _userName = profileData['userName'];
        }
        if (profileData['mail'] != null && (profileData['mail'] as String).isNotEmpty) {
          _userEmail = profileData['mail'];
        }
        if (finalImageUrl != null) {
          _userImage = finalImageUrl;
        }
      });
    } catch (_) {}
  }
  
  // Avatar upload methods
  Future<void> _pickAndUploadAvatar() async {
    if (!_isLoggedIn) {
      _showLoginRequiredDialog();
      return;
    }
    
    // Show image source selection
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildImageSourceBottomSheet(),
    );
  }
  
  Widget _buildImageSourceBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Chọn ảnh đại diện',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImageSourceOption(
                icon: Icons.camera_alt,
                label: 'Chụp ảnh',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              _buildImageSourceOption(
                icon: Icons.photo_library,
                label: 'Thư viện',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppTheme.primaryBlue),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _uploadAvatar(image.path);
      }
    } catch (e) {
      print('❌ Image picker error: $e');
      _showErrorSnackBar('Lỗi khi chọn ảnh: $e');
    }
  }
  
  Future<void> _uploadAvatar(String imagePath) async {
    setState(() {
      _isUploadingAvatar = true;
    });
    
    try {
      // Validate image
      if (!AvatarService().validateImage(imagePath)) {
        _showErrorSnackBar('Ảnh không hợp lệ. Vui lòng chọn ảnh khác.');
        return;
      }
      
      // Compress image
      final compressedPath = await _compressImage(imagePath);
      
      // Upload to server with username (username sẽ được giữ nguyên hoặc cập nhật nếu đã thay đổi)
      final result = await AvatarService().uploadAvatar(compressedPath, _userName);
      
      if (result['success'] == true) {
        // Get image and username from response
        final newImageUrl = result['image'];
        final newUserName = result['userName'];
        
        print('📦 Upload response - image: $newImageUrl, userName: $newUserName');
        
        // Process image URL/data
        String? finalImageUrl;
        if (newImageUrl != null) {
          if (newImageUrl.startsWith('data:image/')) {
            // ✅ Base64 format (RECOMMENDED) - use directly
            finalImageUrl = newImageUrl;
            print('✅ Using base64 image (RECOMMENDED FORMAT)');
          } else if (newImageUrl.startsWith('/')) {
            // ⚠️ Relative path - convert to absolute URL
            finalImageUrl = _cacheBustUrl(newImageUrl);
            print('⚠️ Converted relative path to absolute URL: $finalImageUrl');
            print('💡 TIP: Ask backend to return base64 instead of file path');
          } else if (newImageUrl.startsWith('http')) {
            // HTTP URL - use directly
            finalImageUrl = _cacheBustUrl(newImageUrl);
            print('✅ Using HTTP URL: $finalImageUrl');
          } else {
            // Unknown format - use as-is
            finalImageUrl = newImageUrl;
            print('⚠️ Unknown image format: $finalImageUrl');
          }
        }
        
        // Update UI immediately
        if (mounted) {
          setState(() {
            if (finalImageUrl != null) {
              _userImage = finalImageUrl;
              print('✅ Updated _userImage in UI');
            }
            if (newUserName != null && newUserName.isNotEmpty) {
              _userName = newUserName;
              print('✅ Updated _userName in UI: $_userName');
            }
          });
        }
        
        // Save to cache
        if (finalImageUrl != null) {
          await _saveAvatarToPrefs(finalImageUrl);
          await _updateUserDataImage(finalImageUrl);
          print('✅ Saved avatar to cache');
        }
        if (newUserName != null && newUserName.isNotEmpty) {
          await _updateUsername(newUserName);
          print('✅ Saved username to cache');
        }
        
        _showSuccessSnackBar(result['message'] ?? 'Cập nhật ảnh đại diện thành công!');
        // Fetch the freshest profile data to ensure UI syncs with backend and caches are updated
        await _refreshProfileFromServer();
      } else {
        _showErrorSnackBar('Lỗi upload: ${result['error']}');
      }
    } catch (e) {
      print('❌ Upload error: $e');
      _showErrorSnackBar('Lỗi upload: $e');
    } finally {
      setState(() {
        _isUploadingAvatar = false;
      });
    }
  }
  
  // Update user data with new image
  Future<void> _updateUserDataImage(String newImageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');
      if (userDataJson != null) {
        final userData = json.decode(userDataJson);
        userData['image'] = newImageUrl;
        await prefs.setString('user_data', json.encode(userData));
        print('✅ User image updated in SharedPreferences');
      }
    } catch (e) {
      print('❌ Error updating user image: $e');
    }
  }

  // Build avatar image with proper centering and source handling
  Widget _buildAvatarImage() {
    // ✅ Placeholder với styling đẹp hơn
    final placeholder = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
      Icons.person,
      color: AppTheme.primaryBlue,
      size: 48,
      ),
    );

    if (_userImage == null || _userImage!.isEmpty) {
      return placeholder;
    }

    final String src = _userImage!;

    // ✅ PRIORITY 1: Handle base64 images (RECOMMENDED by backend)
    if (src.startsWith('data:image/')) {
      try {
        final base64String = src.split(',')[1];
        final bytes = base64Decode(base64String);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
          ),
        );
      } catch (e) {
        print('❌ Base64 decode error: $e');
        return placeholder;
      }
    }

    // ⚠️ PRIORITY 2: Handle relative path (DEPRECATED - requires static file serving)
    if (src.startsWith('/')) {
      final urls = _resolveAvatarUrls(src);
      final String absolute = urls['primary'] ?? src;
      final String? fallback = urls['fallback'];
      print('⚠️ Using file path (DEPRECATED) - TIP: Ask backend to return base64 instead');
      bool _hasLoggedSuccess = false; // ✅ Chỉ log 1 lần
      
      return ClipOval(
        child: _buildNetworkAvatarWithFallback(
          primaryUrl: absolute,
          fallbackUrl: fallback,
          placeholder: placeholder,
        ),
      );
    }

    // ✅ PRIORITY 3: Handle absolute HTTP URL (TESTING)
    if (src.startsWith('http')) {
      final urls = _resolveAvatarUrls(src);
      final String primary = urls['primary'] ?? src;
      final String? fallback = urls['fallback'];
      bool _hasLoggedSuccess = false; // ✅ Chỉ log 1 lần

      return ClipOval(
        child: _buildNetworkAvatarWithFallback(
          primaryUrl: primary,
          fallbackUrl: fallback,
          placeholder: placeholder,
        ),
      );
    }

    // PRIORITY 4: Local file path (for temporary preview before upload)
    return ClipOval(
      child: Image.file(
      File(src),
      width: 96,
      height: 96,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('❌ Image.file error: $error');
          return placeholder;
      },
      ),
    );
  }
  
  Future<String> _compressImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Không thể đọc ảnh');
      }
      
      // Resize to max 512x512
      final resized = img.copyResize(
        image,
        width: 512,
        height: 512,
        maintainAspect: true,
      );
      
      // Encode as JPEG with quality 85
      final compressedBytes = img.encodeJpg(resized, quality: 85);
      
      // Save compressed image
      final compressedPath = '${imagePath}_compressed.jpg';
      final compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(compressedBytes);
      
      print('✅ Image compressed: ${bytes.length} → ${compressedBytes.length} bytes');
      return compressedPath;
    } catch (e) {
      print('❌ Compression error: $e');
      return imagePath; // Return original if compression fails
    }
  }
  
  Future<void> _saveAvatarToPrefs(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_avatar', imagePath);
      print('✅ Avatar saved to SharedPreferences');
    } catch (e) {
      print('❌ Error saving avatar: $e');
    }
  }
  
  Future<void> _loadAvatarFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final avatarPath = prefs.getString('user_avatar');
      if (avatarPath != null && File(avatarPath).existsSync()) {
        setState(() {
          _userImage = avatarPath;
        });
        print('✅ Avatar loaded from SharedPreferences');
      }
    } catch (e) {
      print('❌ Error loading avatar: $e');
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cần đăng nhập'),
        content: const Text('Bạn cần đăng nhập để thay đổi ảnh đại diện.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Từ chối'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ModernOnboardingScreen()),
              );
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
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
    
    // Load user data khi khởi tạo
    _loadUserData();
    _loadAvatarFromPrefs();
  }

  // Load thông tin user từ SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');
      final isLoggedIn = await AuthService().isLoggedIn();
      
      // Check có auth_token nhưng không có user_data → Guest mode
      if (isLoggedIn && (userDataJson == null || userDataJson.isEmpty)) {
        print('⚠️ Found auth_token but no user_data - clearing to guest mode');
        await prefs.remove('user_data');
        await prefs.remove('auth_token');
      }
      
      if (!isLoggedIn || userDataJson == null || userDataJson.isEmpty) {
        // Nếu không logged in hoặc không có user data → Guest mode
        await prefs.remove('user_data');
        await prefs.remove('auth_token');
        // KHÔNG xóa 'followed_comics' để giữ lại data
        
        setState(() {
          _isLoggedIn = false;
          _userName = 'Guest User';
          _userEmail = 'Guest Account';
          _userImage = null;
          _userData = null;
        });
        print('ℹ️ Showing guest profile (no user data)');
        return;
      }
      
      // Có đầy đủ thông tin → Load user data
      if (userDataJson.isNotEmpty) {
        final userData = json.decode(userDataJson);
        setState(() {
          _isLoggedIn = true;
          _userName = userData['userName'] ?? 'User';
          _userEmail = userData['mail'] ?? 'user@example.com';
          _userData = userData;
        });
        print('✅ Loaded user data: $_userName ($_userEmail)');
        
        // ✅ Fetch user profile từ server qua API mới (userName, mail, image)
        print('🔄 Fetching user profile from server via API...');
        final profileData = await AuthService().fetchUserProfile();
        
        if (profileData != null && mounted) {
          final String? serverUserName = profileData['userName'];
          final String? serverMail = profileData['mail'];
          final String? serverImage = profileData['image'];
          
          print('📦 Profile data from server:');
          print('   - userName: $serverUserName');
          print('   - mail: $serverMail');
          print('   - image: $serverImage');
          
          // Process image data
          String? finalImageUrl;
          if (serverImage != null && serverImage.isNotEmpty) {
            if (serverImage.startsWith('data:image/')) {
              // ✅ Base64 format (RECOMMENDED) - use directly
              finalImageUrl = serverImage;
              print('✅ Server returned BASE64 image (${serverImage.length} chars)');
            } else if (serverImage.startsWith('http://') || serverImage.startsWith('https://')) {
              // ✅ HTTP URL - use directly (NEW: backend changed to absolute URL)
              finalImageUrl = serverImage;
              print('✅ Server returned HTTP URL: ${serverImage.substring(0, serverImage.length > 80 ? 80 : serverImage.length)}...');
            } else if (serverImage.startsWith('/')) {
              // ⚠️ Relative path - convert to absolute URL
              finalImageUrl = '${AuthService.baseUrl}$serverImage';
              print('⚠️ Server returned relative path, converted to URL');
              print('💡 TIP: Ask backend to return base64 instead');
            } else {
              // Unknown format
              finalImageUrl = serverImage;
              print('⚠️ Unknown image format from server');
            }
          }
          
          // Update UI
          setState(() {
            if (serverUserName != null && serverUserName.isNotEmpty) {
              _userName = serverUserName;
            }
            if (serverMail != null && serverMail.isNotEmpty) {
              _userEmail = serverMail;
            }
            if (finalImageUrl != null) {
              _userImage = finalImageUrl;
            }
          });
          
          // Cache avatar
          if (finalImageUrl != null) {
            await prefs.setString('cached_avatar', finalImageUrl);
            print('✅ Cached avatar for offline use');
          }
          
          // Update user_data
          if (serverUserName != null || serverMail != null) {
            final userDataJson = prefs.getString('user_data');
            if (userDataJson != null) {
              final userData = json.decode(userDataJson);
              if (serverUserName != null) userData['userName'] = serverUserName;
              if (serverMail != null) userData['mail'] = serverMail;
              if (finalImageUrl != null) userData['image'] = finalImageUrl;
              await prefs.setString('user_data', json.encode(userData));
              _userData = userData;
              print('✅ Updated user_data cache');
            }
          }
          
          print('✅ Profile loaded successfully:');
          print('   - userName: $_userName');
          print('   - mail: $_userEmail');
          print('   - image loaded: ${_userImage != null}');
        } else {
          // Fallback: use cached avatar
          print('⚠️ Failed to fetch profile from server, using cache');
          final cachedAvatar = prefs.getString('cached_avatar');
          if (cachedAvatar != null && mounted) {
            setState(() {
              _userImage = cachedAvatar;
            });
            print('📦 Using cached avatar');
          } else {
            setState(() {
              _userImage = null;
            });
            print('⚠️ No cached avatar available');
          }
        }
      }
    } catch (e) {
      print('❌ Error loading user data: $e');
      setState(() {
        _isLoggedIn = false;
        _userName = 'Guest User';
        _userEmail = 'Guest Account';
        _userImage = null;
        _userData = null;
      });
    }
  }

  // Cập nhật thông tin user (được gọi từ Sign In/Sign Up)
  void updateUserData(Map<String, dynamic> userData) {
    setState(() {
      _isLoggedIn = true;
      _userName = userData['userName'] ?? 'User';
      _userEmail = userData['mail'] ?? 'user@example.com';
      _userImage = userData['image'];
      _userData = userData;
    });
    
    // Lưu vào SharedPreferences
    _saveUserData(userData);
    print('✅ Updated user data: $_userName ($_userEmail)');
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

  // Đăng xuất
  Future<void> _logout() async {
    try {
      await AuthRepository().logout();
      final prefs = await SharedPreferences.getInstance();
      // Xóa user data và auth token nhưng GIỮ follow list để khi login lại vẫn có
      await prefs.remove('user_data');
      await prefs.remove('auth_token');
      // KHÔNG xóa 'followed_comics' để giữ lại data khi login lại
      
      setState(() {
        _isLoggedIn = false;
        _userName = 'Guest User';
        _userEmail = 'Guest Account';
        _userImage = null;
        _userData = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng xuất thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      print('✅ User logged out successfully');
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildProfileStats(),
          _buildAchievementsSection(),
          _buildReadingGoalsSection(),
          _buildSettingsSection(),
          _buildAboutSection(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildSliverAppBar() {
    final languageProvider = LanguageProvider.of(context);
    if (languageProvider == null) {
      return const SliverAppBar(
        title: Text('Profile'),
        backgroundColor: AppTheme.primaryBlue,
      );
    }
    
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 240, // ✅ Tăng chiều cao để có đủ không gian
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      foregroundColor: Colors.white,
      centerTitle: true,
      title: Text(
        languageProvider.translate('profile'),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue,
                AppTheme.secondaryBlue,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50), // ✅ Tăng khoảng cách để tránh đè lên "Profile"
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipOval(
                            child: _buildAvatarImage(),
                          ),
                          if (_isUploadingAvatar)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _isLoggedIn ? _userEmail : languageProvider.translate('guest_account'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: _showSettingsMenu, // Thay đổi: hiện menu thay vì dialog
        ),
      ],
    );
  }

  Widget _buildProfileStats() {
    final languageProvider = LanguageProvider.of(context);
    if (languageProvider == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  languageProvider.translate('reading_statistics'),
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(languageProvider.translate('books_read'), '24', Icons.book, AppTheme.primaryBlue),
                    _buildStatCard(languageProvider.translate('pages_read'), '8,420', Icons.pages, AppTheme.accentGreen),
                    _buildStatCard(languageProvider.translate('reading_streak'), '15 ${languageProvider.translate('days')}', Icons.local_fire_department, AppTheme.accentRed),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(languageProvider.translate('hours_read'), '156', Icons.access_time, AppTheme.secondaryBlue),
                    _buildStatCard(languageProvider.translate('avg_rating'), '4.6', Icons.star, Colors.amber),
                    _buildStatCard(languageProvider.translate('genres'), '8', Icons.category, AppTheme.lightBlue),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
          ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    final languageProvider = LanguageProvider.of(context);
    if (languageProvider == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏆 ${languageProvider.translate('achievements')}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return _buildAchievementCard(index);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementCard(int index) {
    final achievements = [
      {'title': 'First Book', 'desc': 'Read your first book', 'icon': Icons.book, 'completed': true},
      {'title': 'Speed Reader', 'desc': 'Read 10 books in a month', 'icon': Icons.speed, 'completed': true},
      {'title': 'Genre Explorer', 'desc': 'Read 5 different genres', 'icon': Icons.explore, 'completed': true},
      {'title': 'Night Owl', 'desc': 'Read 50 pages at night', 'icon': Icons.nightlight_round, 'completed': false},
      {'title': 'Scholar', 'desc': 'Read 100 books total', 'icon': Icons.school, 'completed': false},
    ];
    
    final achievement = achievements[index];
    final isCompleted = achievement['completed'] as bool;
    
    final theme = Theme.of(context);
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.accentGreen : AppTheme.lightBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              achievement['icon'] as IconData,
              color: isCompleted ? Colors.white : AppTheme.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement['title'] as String,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            achievement['desc'] as String,
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildReadingGoalsSection() {
    final languageProvider = LanguageProvider.of(context);
    if (languageProvider == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '📚 ${languageProvider.translate('reading_goals')}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: _showGoalsDialog,
                      child: Text(
                        languageProvider.translate('edit'),
                        style: const TextStyle(color: AppTheme.primaryBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGoalItem(languageProvider.translate('books_this_year'), 24, 50, 'books'),
                const SizedBox(height: 12),
                _buildGoalItem(languageProvider.translate('pages_this_month'), 1200, 2000, 'pages'),
                const SizedBox(height: 12),
                _buildGoalItem(languageProvider.translate('reading_streak'), 15, 30, languageProvider.translate('days')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalItem(String title, int current, int target, String unit) {
    final progress = current / target;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '$current / $target $unit',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.brightness == Brightness.dark
              ? AppTheme.darkDivider
              : AppTheme.lightBlue.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 1.0 ? AppTheme.accentGreen : AppTheme.primaryBlue,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    final languageProvider = LanguageProvider.of(context);
    if (languageProvider == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingsItem(
                  Icons.notifications,
                  languageProvider.translate('notifications'),
                  languageProvider.translate('manage_notifications'),
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                    activeColor: AppTheme.primaryBlue,
                  ),
                ),
                _buildDivider(),
                Builder(
                  builder: (context) {
                    final themeProvider = ThemeProvider.of(context);
                    if (themeProvider == null) {
                      return _buildSettingsItem(
                        Icons.dark_mode,
                        languageProvider.translate('dark_mode'),
                        languageProvider.translate('switch_dark_theme'),
                        Switch(
                          value: false,
                          onChanged: (value) {},
                          activeColor: AppTheme.primaryBlue,
                        ),
                      );
                    }
                    
                    return _buildSettingsItem(
                      Icons.dark_mode,
                      languageProvider.translate('dark_mode'),
                      languageProvider.translate('switch_dark_theme'),
                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value 
                                  ? languageProvider.translate('switch_dark_mode')
                                  : languageProvider.translate('switch_light_mode')),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        activeColor: AppTheme.primaryBlue,
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _buildSettingsItem(
                  Icons.alarm,
                  languageProvider.translate('reading_reminders'),
                  languageProvider.translate('daily_reading_reminders'),
                  Switch(
                    value: _readingReminders,
                    onChanged: (value) {
                      setState(() {
                        _readingReminders = value;
                      });
                    },
                    activeColor: AppTheme.primaryBlue,
                  ),
                ),
                _buildDivider(),
                _buildSettingsItem(
                  Icons.language,
                  languageProvider.translate('language'),
                  languageProvider.translate('select_language'),
                  const Icon(Icons.chevron_right, color: AppTheme.textLight),
                  onTap: () => _showLanguageDialog(languageProvider),
                ),
                _buildDivider(),
                _buildSettingsItem(
                  Icons.text_fields,
                  languageProvider.translate('font_size'),
                  _selectedFontSize,
                  const Icon(Icons.chevron_right, color: AppTheme.textLight),
                  onTap: _showFontSizeDialog,
                ),
                // Thêm nút đăng xuất nếu user đã đăng nhập
                if (_isLoggedIn) ...[
                  _buildDivider(),
                  _buildSettingsItem(
                    Icons.logout,
                    'Đăng xuất',
                    'Đăng xuất khỏi tài khoản',
                    const Icon(Icons.chevron_right, color: AppTheme.textLight),
                    onTap: _showLogoutDialog,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    String subtitle,
    Widget trailing, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.lightBlue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryBlue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    final theme = Theme.of(context);
    return Divider(
      height: 1,
      color: theme.dividerColor,
      indent: 60,
    );
  }

  // Hiển thị dialog xác nhận đăng xuất
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    final languageProvider = LanguageProvider.of(context);
    if (languageProvider == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSettingsItem(
                  Icons.info_outline,
                  languageProvider.translate('about_storyverse'),
                  '${languageProvider.translate('version')} 1.0.0',
                  const Icon(Icons.chevron_right, color: AppTheme.textLight),
                  onTap: _showAboutDialog,
                ),
                _buildDivider(),
                _buildSettingsItem(
                  Icons.help_outline,
                  languageProvider.translate('help_support'),
                  languageProvider.translate('get_help'),
                  const Icon(Icons.chevron_right, color: AppTheme.textLight),
                  onTap: _showHelpDialog,
                ),
                _buildDivider(),
                _buildSettingsItem(
                  Icons.privacy_tip_outlined,
                  languageProvider.translate('privacy_policy'),
                  languageProvider.translate('read_privacy'),
                  const Icon(Icons.chevron_right, color: AppTheme.textLight),
                  onTap: _showPrivacyDialog,
                ),
                // Chỉ hiển thị nút Sign In nếu user chưa đăng nhập (guest)
                if (!_isLoggedIn) ...[
                  _buildDivider(),
                  _buildSettingsItem(
                    Icons.login,
                    languageProvider.translate('log_in'),
                    languageProvider.translate('log_in_account'),
                    const Icon(Icons.chevron_right, color: AppTheme.accentRed),
                    onTap: _showLoginDialog,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Menu hiển thị khi click nút Settings
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Option 1: Thay đổi thông tin (Avatar + Username)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryBlue,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Thay đổi thông tin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Cập nhật ảnh đại diện và tên tài khoản',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditProfileDialog();
                },
              ),
              
              const Divider(height: 1),
              
              // Option 2: Thay đổi mật khẩu
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: AppTheme.primaryOrange,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'Thay đổi mật khẩu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Cập nhật mật khẩu của bạn',
                  style: TextStyle(fontSize: 13),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showChangePasswordDialog();
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog thay đổi thông tin (Avatar + Username)
  void _showEditProfileDialog() {
    final TextEditingController usernameController = TextEditingController(text: _userName);
    String? tempImagePath; // Lưu ảnh tạm thời trước khi upload
    bool isLoadingImage = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Thay đổi thông tin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar section
                GestureDetector(
                  onTap: () async {
                    // Show image source selection
                    showModalBottomSheet(
                      context: context,
                      builder: (bottomSheetContext) => Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Chọn ảnh đại diện',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildImageSourceOption(
                                  icon: Icons.camera_alt,
                                  label: 'Camera',
                                  onTap: () async {
                                    Navigator.pop(bottomSheetContext);
                                    setDialogState(() {
                                      isLoadingImage = true;
                                    });
                                    
                                    try {
                                      final XFile? image = await _imagePicker.pickImage(
                                        source: ImageSource.camera,
                                        maxWidth: 1024,
                                        maxHeight: 1024,
                                        imageQuality: 85,
                                      );
                                      
                                      if (image != null) {
                                        setDialogState(() {
                                          tempImagePath = image.path;
                                          isLoadingImage = false;
                                        });
                                      } else {
                                        setDialogState(() {
                                          isLoadingImage = false;
                                        });
                                      }
                                    } catch (e) {
                                      setDialogState(() {
                                        isLoadingImage = false;
                                      });
                                      _showErrorSnackBar('Lỗi khi chụp ảnh: $e');
                                    }
                                  },
                                ),
                                _buildImageSourceOption(
                                  icon: Icons.photo_library,
                                  label: 'Thư viện',
                                  onTap: () async {
                                    Navigator.pop(bottomSheetContext);
                                    setDialogState(() {
                                      isLoadingImage = true;
                                    });
                                    
                                    try {
                                      final XFile? image = await _imagePicker.pickImage(
                                        source: ImageSource.gallery,
                                        maxWidth: 1024,
                                        maxHeight: 1024,
                                        imageQuality: 85,
                                      );
                                      
                                      if (image != null) {
                                        setDialogState(() {
                                          tempImagePath = image.path;
                                          isLoadingImage = false;
                                        });
                                      } else {
                                        setDialogState(() {
                                          isLoadingImage = false;
                                        });
                                      }
                                    } catch (e) {
                                      setDialogState(() {
                                        isLoadingImage = false;
                                      });
                                      _showErrorSnackBar('Lỗi khi chọn ảnh: $e');
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryBlue, width: 2),
                        ),
                        child: ClipOval(
                          child: _buildDialogAvatarImage(tempImagePath),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                      if (isLoadingImage)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Chạm để thay đổi ảnh',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                
                // Username field
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên tài khoản',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUsername = usernameController.text.trim();
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                // Đóng dialog
                Navigator.pop(context);
                
                // Hiện loading
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Đang cập nhật...'),
                      ],
                    ),
                    duration: Duration(seconds: 30),
                  ),
                );
                
                // Upload avatar nếu có ảnh mới
                if (tempImagePath != null) {
                  await _uploadAvatar(tempImagePath!);
                }
                
                // Update username nếu có thay đổi
                if (newUsername.isNotEmpty && newUsername != _userName) {
                  final result = await AvatarService().updateUsernameOnly(newUsername);
                  
                  scaffoldMessenger.hideCurrentSnackBar();
                  
                  if (result['success'] == true) {
                    final newUserNameFromServer = result['userName'];
                    if (newUserNameFromServer != null && newUserNameFromServer.isNotEmpty) {
                      if (mounted) {
                        setState(() {
                          _userName = newUserNameFromServer;
                        });
                      }
                      await _updateUsername(newUserNameFromServer);
                      await _updateUserDataUsername(newUserNameFromServer);
                      
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('✅ Cập nhật thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(result['error'] ?? 'Cập nhật thất bại!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  scaffoldMessenger.hideCurrentSnackBar();
                  if (tempImagePath != null) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('✅ Cập nhật ảnh thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build avatar image for dialog (preview temporary image)
  Widget _buildDialogAvatarImage(String? tempPath) {
    if (tempPath != null) {
      // Show temporary selected image
      return Image.file(
        File(tempPath),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      );
    }
    
    // Show current avatar
    return _buildAvatarImage();
  }

  // Dialog thay đổi mật khẩu (sử dụng flow OTP)
  void _showChangePasswordDialog() {
    final TextEditingController emailController = TextEditingController(text: _userEmail);
    final TextEditingController otpController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool otpSent = false;
    bool isLoadingOtp = false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Thay đổi mật khẩu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!otpSent) ...[
                  // Bước 1: Nhập email và gửi OTP
                  const Text(
                    'Chúng tôi sẽ gửi mã OTP đến email của bạn để xác thực',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    enabled: false, // Pre-filled, không cho sửa
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Color(0xFFF5F5F5),
                    ),
                  ),
                ] else ...[
                  // Bước 2: Nhập OTP và mật khẩu mới
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Mã OTP',
                      hintText: 'Nhập mã OTP từ email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.security),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu mới',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_reset),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            if (!otpSent)
              ElevatedButton(
                onPressed: isLoadingOtp ? null : () async {
                  // Bước 1: Gửi OTP
                  if (emailController.text.trim().isEmpty) {
                    _showErrorSnackBar('Email không hợp lệ!');
                    return;
                  }
                  
                  setDialogState(() {
                    isLoadingOtp = true;
                  });
                  
                  final result = await AuthRepository().requestPasswordReset(
                    email: emailController.text.trim(),
                  );
                  
                  setDialogState(() {
                    isLoadingOtp = false;
                  });
                  
                  if (result['success'] == true) {
                    setDialogState(() {
                      otpSent = true;
                    });
                    _showSuccessSnackBar('Mã OTP đã được gửi đến email của bạn!');
                  } else {
                    _showErrorSnackBar(result['error'] ?? 'Gửi OTP thất bại!');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: isLoadingOtp
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Gửi mã OTP'),
              )
            else
              ElevatedButton(
                onPressed: () async {
                  // Bước 2: Xác thực OTP và đổi mật khẩu
                  final otp = otpController.text.trim();
                  final newPassword = newPasswordController.text.trim();
                  final confirmPassword = confirmPasswordController.text.trim();
                  
                  if (otp.isEmpty) {
                    _showErrorSnackBar('Vui lòng nhập mã OTP!');
                    return;
                  }
                  
                  if (newPassword.isEmpty) {
                    _showErrorSnackBar('Vui lòng nhập mật khẩu mới!');
                    return;
                  }
                  
                  if (newPassword != confirmPassword) {
                    _showErrorSnackBar('Mật khẩu xác nhận không khớp!');
                    return;
                  }
                  
                  if (newPassword.length < 6) {
                    _showErrorSnackBar('Mật khẩu mới phải có ít nhất 6 ký tự!');
                    return;
                  }
                  
                  // Hiện loading
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 16),
                          Text('Đang đổi mật khẩu...'),
                        ],
                      ),
                      duration: Duration(seconds: 30),
                    ),
                  );
                  
                  // Gọi API reset password với OTP
                  final result = await AuthRepository().resetPassword(
                    email: emailController.text.trim(),
                    otp: otp,
                    newPassword: newPassword,
                  );
                  
                  // Ẩn loading snackbar
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  
                  if (result['success'] == true) {
                    _showSuccessSnackBar('Đổi mật khẩu thành công!');
                    
                    // Đăng xuất và yêu cầu đăng nhập lại với mật khẩu mới
                    Future.delayed(const Duration(seconds: 2), () async {
                      await AuthRepository().logout();
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/onboarding', (route) => false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng đăng nhập lại với mật khẩu mới'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      }
                    });
                  } else {
                    _showErrorSnackBar(result['error'] ?? 'Đổi mật khẩu thất bại!');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Đổi mật khẩu'),
              ),
          ],
        ),
      ),
    );
  }

  // Update username in SharedPreferences
  Future<void> _updateUsername(String newUsername) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');
      if (userDataJson != null) {
        final userData = json.decode(userDataJson);
        userData['userName'] = newUsername;
        await prefs.setString('user_data', json.encode(userData));
        print('✅ Username updated in SharedPreferences');
      }
    } catch (e) {
      print('❌ Error updating username: $e');
    }
  }
  
  // Update username in user_data (giống _updateUsername nhưng rõ ràng hơn)
  Future<void> _updateUserDataUsername(String newUsername) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataJson = prefs.getString('user_data');
      if (userDataJson != null) {
        final userData = json.decode(userDataJson);
        userData['userName'] = newUsername;
        await prefs.setString('user_data', json.encode(userData));
        
        // ✅ Cập nhật biến _userData để UI refresh
        _userData = userData;
        
        print('✅ Username updated in user_data: $newUsername');
      }
    } catch (e) {
      print('❌ Error updating user_data username: $e');
    }
  }

  void _showGoalsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reading Goals'),
        content: const Text('Set your reading goals for this year!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Set Goals'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.translate('select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('en', languageProvider.getLanguageName('en'), languageProvider),
            _buildLanguageOption('vi', languageProvider.getLanguageName('vi'), languageProvider),
            _buildLanguageOption('es', languageProvider.getLanguageName('es'), languageProvider),
            _buildLanguageOption('fr', languageProvider.getLanguageName('fr'), languageProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String languageCode, String label, LanguageProvider languageProvider) {
    return ListTile(
      title: Text(label),
      trailing: LanguageManager.currentLanguageCode == languageCode
          ? const Icon(Icons.check, color: AppTheme.primaryBlue)
          : null,
      onTap: () {
        LanguageManager.changeLanguage(languageCode);
        Navigator.pop(context);
      },
    );
  }

  void _showFontSizeDialog() {
    final languageProvider = LanguageProvider.of(context);
    if (languageProvider == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.translate('font_size')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFontSizeOption('Small', languageProvider.translate('small')),
            _buildFontSizeOption('Medium', languageProvider.translate('medium')),
            _buildFontSizeOption('Large', languageProvider.translate('large')),
            _buildFontSizeOption('Extra Large', languageProvider.translate('extra_large')),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeOption(String value, String label) {
    return ListTile(
      title: Text(label),
      trailing: _selectedFontSize == value
          ? const Icon(Icons.check, color: AppTheme.primaryBlue)
          : null,
      onTap: () {
        setState(() {
          _selectedFontSize = value;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About StoryVerse'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('StoryVerse is your ultimate reading companion. Discover, read, and track your favorite books with our beautiful and intuitive interface.'),
            SizedBox(height: 16),
            Text('© 2024 StoryVerse. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Need help? We\'re here for you!'),
            SizedBox(height: 16),
            Text('📧 Email: support@storyverse.com'),
            Text('📞 Phone: +1 (555) 123-4567'),
            Text('💬 Live Chat: Available 24/7'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. This privacy policy explains how we collect, use, and protect your information when you use StoryVerse.\n\n'
            'Information We Collect:\n'
            '• Account information (name, email)\n'
            '• Reading preferences and history\n'
            '• App usage statistics\n\n'
            'How We Use Your Information:\n'
            '• To provide personalized recommendations\n'
            '• To improve our services\n'
            '• To communicate with you\n\n'
            'We never sell your personal information to third parties.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLoginDialog() async {
    final languageProvider = LanguageProvider.of(context);
    if (languageProvider == null) return;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ModernOnboardingScreen(),
      ),
    );
    
    // Handle login result
    if (result != null && result['isLoggedIn'] == true) {
      setState(() {
        _isLoggedIn = true;
        _userName = result['userName'] ?? 'User';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(languageProvider.translate('login_successful'))),
      );
    }
  }

  Widget _buildBottomNavigation() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CommonBottomNav(
      currentIndex: _selectedIndex,
      isDark: isDark,
      onTap: (index) {
        if (index == _selectedIndex) return;
        setState(() => _selectedIndex = index);

        Widget? destination;
        switch (index) {
          case 0:
            destination = const EnhancedHomeScreen();
            break;
          case 1:
            destination = const ExploreScreen();
            break;
          case 2:
            destination = const BookListScreen();
            break;
          case 3:
            return; // Đang ở Profile
        }

        if (destination != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => destination!),
          );
        }
      },
    );
  }
}