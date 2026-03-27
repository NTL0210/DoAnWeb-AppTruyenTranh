# 📚 StoryVerse - Nền Tảng Đọc Truyện Hiện Đại

> **"Your Reading Adventure Starts Here"** - Trải nghiệm đọc truyện tranh, light novel và tiểu thuyết mới mẻ với giao diện hiện đại, tính năng thông minh.

[![Flutter](https://img.shields.io/badge/Flutter-3.7.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7.0-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🌟 Giới Thiệu

**StoryVerse** là ứng dụng đọc truyện đa nền tảng được xây dựng bằng Flutter, mang đến trải nghiệm đọc truyện mượt mà và hiện đại. Ứng dụng hỗ trợ đọc truyện tranh (Comic/Manga), light novel và tiểu thuyết với nhiều tính năng thông minh.

### ✨ Điểm Nổi Bật

- 📖 **Thư viện phong phú**: Hàng ngàn đầu truyện được cập nhật liên tục
- 🔔 **Thông báo real-time**: Nhận thông báo ngay khi có chương mới qua SignalR
- 🎨 **Giao diện đẹp mắt**: Thiết kế hiện đại với chế độ sáng/tối
- 🌐 **Đa ngôn ngữ**: Hỗ trợ tiếng Việt và tiếng Anh
- 📱 **Đọc offline**: Lưu trữ lịch sử đọc và tiến độ cá nhân
- 🔍 **Tìm kiếm thông minh**: Tìm truyện theo tên, thể loại, tác giả
- ❤️ **Quản lý yêu thích**: Theo dõi và quản lý truyện ưa thích
- 👤 **Tài khoản cá nhân**: Đồng bộ dữ liệu trên nhiều thiết bị

---

## 📱 Tính Năng Chi Tiết

### 🏠 Trang Chủ (Home)
- **Banner nổi bật**: Hiển thị truyện hot, trending
- **Đề xuất cá nhân**: Gợi ý truyện dựa trên sở thích
- **Tiếp tục đọc**: Truy cập nhanh truyện đang đọc dở
- **Truyện mới cập nhật**: Theo dõi chương mới nhất
- **Phân loại đa dạng**: Comic, Manga, Light Novel, Novel

### 🔍 Khám Phá (Explore)
- **Tìm kiếm nâng cao**: Tìm theo tên, tác giả, từ khóa
- **Lọc theo thể loại**: Action, Romance, Fantasy, Sci-Fi, Mystery, Horror...
- **Sắp xếp linh hoạt**: Theo độ phổ biến, đánh giá, ngày cập nhật
- **Hiển thị đa dạng**: Chế độ lưới (Grid) hoặc danh sách (List)
- **Tải thêm tự động**: Cuộn vô hạn với pagination

### 📚 Thư Viện Của Tôi (My Library)
- **Truyện đang đọc**: Hiển thị tiến độ đọc (%)
- **Truyện đã hoàn thành**: Lịch sử đọc hoàn chỉnh
- **Thống kê cá nhân**: Số truyện, số trang đã đọc
- **Đồng bộ cloud**: Backup dữ liệu với tài khoản
- **Tìm kiếm nhanh**: Lọc trong thư viện cá nhân

### 👤 Hồ Sơ (Profile)
- **Thông tin tài khoản**: Avatar, username, email
- **Thống kê đọc truyện**: Số truyện đã đọc, điểm kinh nghiệm
- **Cài đặt ứng dụng**:
  - Chế độ sáng/tối (Light/Dark mode)
  - Đổi ngôn ngữ (Tiếng Việt/English)
  - Cỡ chữ đọc truyện
  - Thông báo và nhắc nhở
- **Đăng nhập/Đăng ký**: 
  - Đăng nhập bằng email
  - Đăng nhập Google
  - Chế độ khách (Guest mode)

### 📖 Đọc Truyện
- **Trình đọc mượt mà**: Cuộn dọc tự nhiên cho comic/manga
- **Điều khiển dễ dàng**: Tap để hiện/ẩn thanh công cụ
- **Chuyển chương nhanh**: Nút Previous/Next chapter
- **Đánh dấu đã đọc**: Tự động lưu tiến độ
- **Zoom ảnh**: Phóng to/thu nhỏ trang truyện
- **Đọc offline**: Cache ảnh để đọc không cần mạng

### 🔔 Thông Báo Real-time
- **SignalR WebSocket**: Kết nối real-time với server
- **Thông báo chương mới**: Nhận ngay khi truyện theo dõi có chập mới
- **Thông báo gợi ý**: Đề xuất truyện phù hợp sở thích
- **Lịch sử thông báo**: Xem lại tất cả thông báo
- **Điều hướng nhanh**: Tap vào thông báo để đọc ngay

---

## 🛠️ Công Nghệ Sử Dụng

### Frontend Framework
- **Flutter 3.7.0**: Framework UI đa nền tảng
- **Dart 3.7.0**: Ngôn ngữ lập trình

### Thư Viện Chính
```yaml
# Mạng & API
http: ^1.1.0                    # HTTP client
dio: ^5.4.0                     # Advanced HTTP client
signalr_core: ^1.1.1            # Real-time communication

# Lưu trữ dữ liệu
shared_preferences: ^2.2.2      # Local storage
flutter_secure_storage: ^9.0.0  # Secure token storage

# Authentication
google_sign_in: ^6.1.5          # Google OAuth

# Media
image_picker: ^1.0.5            # Pick images
video_player: ^2.10.0           # Video player
image: ^4.0.17                  # Image processing

# Utilities
intl: ^0.18.1                   # Internationalization
collection: ^1.18.0             # Collection utilities
json_annotation: ^4.8.1         # JSON serialization

# Testing
mockito: ^5.4.4                 # Mocking
build_runner: ^2.4.7            # Code generation
flutter_test: sdk               # Testing framework
```

### Kiến Trúc
```
lib/
├── main.dart                          # Entry point
├── core/
│   └── storage/                       # Storage utilities
├── data/
│   ├── models/                        # Data models
│   │   ├── comic.dart                 # Comic model
│   │   ├── comic_chapter.dart         # Chapter model
│   │   ├── comic_genre.dart           # Genre model
│   │   └── crawl_notification.dart    # Notification model
│   ├── repositories/                  # Data repositories
│   │   ├── auth_repository.dart
│   │   └── comic_repository.dart
│   └── services/                      # Services
│       ├── auth_service.dart
│       ├── comic_service.dart
│       └── notification_service.dart  # SignalR service
├── presentation/
│   └── providers/                     # State management
├── providers/
│   └── language_provider.dart         # i18n provider
├── screens/                           # UI Screens
│   ├── modern_onboarding.dart         # Onboarding
│   ├── modern_signup_genre.dart       # Sign in/up
│   ├── enhanced_home_screen.dart      # Home
│   ├── explore_screen.dart            # Explore
│   ├── booklist_screen.dart           # My library
│   ├── book_details_screen.dart       # Comic details
│   ├── chapter_reader_screen.dart     # Reader
│   ├── profile_screen.dart            # Profile
│   ├── notification_list_screen.dart  # Notifications
│   └── forgot_password_screen.dart    # Password recovery
├── services/
│   └── api_service.dart               # API client
├── theme/
│   └── app_theme.dart                 # App theme
└── widgets/                           # Reusable widgets
    ├── comic_card.dart
    ├── genre_chips.dart
    ├── search_bar_widget.dart
    ├── loading_indicator.dart
    ├── notification_badge.dart
    └── common_bottom_nav.dart
```

---

## 🚀 Hướng Dẫn Cài Đặt

### Yêu Cầu Hệ Thống
- Flutter SDK: >= 3.7.0
- Dart SDK: >= 3.7.0
- Android Studio / VS Code
- Android: API level 21+ (Android 5.0+)
- iOS: iOS 12.0+

### Các Bước Cài Đặt

1. **Clone repository**
```bash
git clone https://github.com/your-username/storyverse.git
cd storyverse
```

2. **Cài đặt dependencies**
```bash
flutter pub get
```

3. **Kiểm tra cấu hình Flutter**
```bash
flutter doctor
```

4. **Chạy ứng dụng**
```bash
# Chạy trên Android
flutter run

# Chạy trên iOS
flutter run -d ios

# Chạy trên Web
flutter run -d chrome
```

5. **Build production**
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

---

## 🔧 Cấu Hình

### API Configuration
Cấu hình API endpoint trong `lib/services/api_service.dart`:
```dart
class ApiService {
  static const String _baseUrl = 'YOUR_API_URL';
  // ...
}
```

### SignalR Configuration
Cấu hình SignalR trong `lib/data/services/notification_service.dart`:
```dart
class NotificationService {
  static const String _baseUrl = 'YOUR_SIGNALR_URL';
  static const String _hubPath = '/hubs/notifications';
  // ...
}
```

---

## 📸 Screenshots

### Onboarding & Authentication
<div align="center">
  <img src="docs/screenshots/onboarding.png" width="250" alt="Onboarding"/>
  <img src="docs/screenshots/signin.png" width="250" alt="Sign In"/>
  <img src="docs/screenshots/genre.png" width="250" alt="Genre Selection"/>
</div>

### Main Features
<div align="center">
  <img src="docs/screenshots/home.png" width="250" alt="Home"/>
  <img src="docs/screenshots/explore.png" width="250" alt="Explore"/>
  <img src="docs/screenshots/library.png" width="250" alt="Library"/>
</div>

### Reading Experience
<div align="center">
  <img src="docs/screenshots/details.png" width="250" alt="Book Details"/>
  <img src="docs/screenshots/reader.png" width="250" alt="Chapter Reader"/>
  <img src="docs/screenshots/notifications.png" width="250" alt="Notifications"/>
</div>

---

## 🧪 Testing

### Chạy tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/services/api_service_test.dart
```

### Test Structure
```
test/
├── repositories/
│   ├── auth_repository_test.dart
│   └── comic_repository_test.dart
├── services/
│   ├── auth_service_test.dart
│   └── comic_service_test.dart
└── widget_test.dart
```

---

## 🎨 Design System

### Color Palette
```dart
Primary Blue:    #2563EB (rgb(37, 99, 235))
Secondary Blue:  #3B82F6 (rgb(59, 130, 246))
Light Blue:      #DBEAFE (rgb(219, 234, 254))
Accent Green:    #10B981 (rgb(16, 185, 129))
Text Dark:       #1F2937 (rgb(31, 41, 55))
Text Medium:     #6B7280 (rgb(107, 114, 128))
Text Light:      #9CA3AF (rgb(156, 163, 175))
```

### Typography
- **Font Family**: System Default (San Francisco iOS, Roboto Android)
- **Font Sizes**: 12px, 14px, 16px, 18px, 20px, 24px, 32px

---

## 🤝 Đóng Góp

Chúng tôi hoan nghênh mọi đóng góp! Vui lòng làm theo các bước sau:

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

### Coding Standards
- Tuân thủ [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Sử dụng `flutter analyze` để check code
- Viết tests cho tính năng mới
- Comment code rõ ràng (tiếng Việt hoặc tiếng Anh)

---

## 📝 Roadmap

### Version 1.1.0 (Coming Soon)
- [ ] Offline reading mode với download chapters
- [ ] Reading statistics và achievements
- [ ] Social features (comment, rating, review)
- [ ] Đọc sách PDF/EPUB
- [ ] Text-to-Speech cho light novel

### Version 1.2.0 (Future)
- [ ] Recommendation system với AI
- [ ] Community forums
- [ ] Author profiles và following
- [ ] Reading challenges và leaderboards
- [ ] Apple Watch companion app

---

## 📄 License

Dự án này được phân phối dưới giấy phép MIT. Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

---

## 🙏 Cảm Ơn

- [Flutter](https://flutter.dev) - Framework tuyệt vời
- [OTruyen API](https://otruyenapi.com) - Nguồn dữ liệu truyện
- [SignalR](https://dotnet.microsoft.com/apps/aspnet/signalr) - Real-time communication
- [Material Design](https://material.io) - Design guidelines
- Cộng đồng Flutter Việt Nam

---

<div align="center">
  <p>Made with ❤️ by StoryVerse Team</p>
  <p>⭐ Star this repo if you like it!</p>
</div>
