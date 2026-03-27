import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';

/// Shared Bottom Navigation Bar Widget — nâng cấp UI premium
/// Dùng cho tất cả screens (old & new)
class CommonBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  const CommonBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = LanguageProvider.of(context);
    final translate = languageProvider?.translate ?? LanguageManager.translate;

    return Container(
      decoration: BoxDecoration(
        // Gradient nền nhẹ làm nổi bật bottom nav
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [Colors.white, Color(0xFFF8FAFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        boxShadow: AppTheme.navShadow,
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppTheme.getBrandPrimary(context),
        unselectedItemColor:
            isDark ? AppTheme.darkTextTertiary : AppTheme.textLight,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: [
          _buildNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: translate('home'),
            index: 0,
            color: AppTheme.getBrandPrimary(context),
            isDark: isDark,
          ),
          _buildNavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore_rounded,
            label: translate('explore'),
            index: 1,
            color: AppTheme.getBrandAccent(context),
            isDark: isDark,
          ),
          _buildNavItem(
            icon: Icons.bookmark_outline_rounded,
            activeIcon: Icons.bookmark_rounded,
            label: translate('book_list'),
            index: 2,
            color: AppTheme.getBrandHighlight(context),
            isDark: isDark,
          ),
          _buildNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: translate('profile'),
            index: 3,
            color: AppTheme.getBrandSupport(context),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  /// Tạo nav item với dot indicator khi active
  BottomNavigationBarItem _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required Color color,
    required bool isDark,
  }) {
    final bool isActive = currentIndex == index;
    return BottomNavigationBarItem(
      icon: _NavIcon(icon: icon, isActive: false, color: color, isDark: isDark),
      activeIcon: _NavIcon(icon: activeIcon, isActive: true, color: color, isDark: isDark),
      label: label,
    );
  }
}

/// Widget nội bộ — icon tab với dot indicator khi active
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color color;
  final bool isDark;

  const _NavIcon({
    required this.icon,
    required this.isActive,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Chấm indicator trên đỉnh icon khi active
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          width: isActive ? 20 : 0,
          height: isActive ? 3 : 0,
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [color, color.withOpacity(0.5)],
                  )
                : null,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (isActive) const SizedBox(height: 4),
        // Nền tròn mờ khi active
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24),
        ),
      ],
    );
  }
}
