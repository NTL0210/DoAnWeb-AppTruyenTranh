import 'package:flutter/material.dart';
import '../data/models/comic.dart';
import '../screens/book_details_screen.dart';
import '../theme/app_theme.dart';

/// Shared Comic Card Widget — nâng cấp UI premium
/// Dùng cho cả old screens và Riverpod screens
class ComicCard extends StatelessWidget {
  final Comic comic;
  final bool isDark;

  const ComicCard({
    super.key,
    required this.comic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailsScreen(slug: comic.slug),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
          // Viền mỏng tinh tế
          border: Border.all(
            color: isDark
                ? AppTheme.darkDivider.withOpacity(0.5)
                : AppTheme.dividerColor.withOpacity(0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.25)
                  : AppTheme.getBrandPrimary(context).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(context),
            _buildInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              comic.thumbUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF334155), const Color(0xFF1E293B)]
                          : [const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: isDark ? AppTheme.darkTextTertiary : AppTheme.textLight,
                    size: 32,
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF334155), const Color(0xFF1E293B)]
                          : [const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: AppTheme.getBrandPrimary(context),
                    ),
                  ),
                );
              },
            ),
            // Overlay gradient mờ phía dưới thumbnail
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0x88000000), Colors.transparent],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comic.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          if (comic.chaptersLatest.isNotEmpty)
            Text(
              comic.chaptersLatest,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.getBrandPrimary(context).withOpacity(0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 6),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: comic.status.toLowerCase().contains('hoàn')
                  ? AppTheme.getBrandAccent(context).withOpacity(0.12)
                  : AppTheme.getBrandPrimary(context).withOpacity(0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 10,
                  color: comic.status.toLowerCase().contains('hoàn')
                      ? AppTheme.getBrandAccent(context)
                      : AppTheme.getBrandPrimary(context),
                ),
                const SizedBox(width: 4),
                Text(
                  comic.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: comic.status.toLowerCase().contains('hoàn')
                        ? AppTheme.getBrandAccent(context)
                        : AppTheme.getBrandPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact list tile version — nâng cấp UI premium
class ComicListTile extends StatelessWidget {
  final Comic comic;
  final bool isDark;

  const ComicListTile({
    super.key,
    required this.comic,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailsScreen(slug: comic.slug),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppTheme.darkCard : AppTheme.cardWhite,
          border: Border.all(
            color: isDark
                ? AppTheme.darkDivider.withOpacity(0.4)
                : AppTheme.dividerColor.withOpacity(0.6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : AppTheme.getBrandPrimary(context).withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail với bo góc đẹp hơn
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                comic.thumbUrl,
                width: 60,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  return Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF334155), const Color(0xFF1E293B)]
                            : [const Color(0xFFE2E8F0), const Color(0xFFDBEAFE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: isDark ? AppTheme.darkTextTertiary : AppTheme.textLight,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comic.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textDark,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (comic.chaptersLatest.isNotEmpty)
                    Text(
                      comic.chaptersLatest,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.getBrandPrimary(context).withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.getBrandPrimary(context).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      comic.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getBrandPrimary(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.getBrandPrimary(context).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppTheme.darkTextTertiary : AppTheme.textMedium,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
