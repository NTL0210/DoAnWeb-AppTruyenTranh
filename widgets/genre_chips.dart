import 'package:flutter/material.dart';
import '../data/models/genre.dart';

/// Shared Genre Chips Widget
/// Dùng cho ExploreScreen (old & new)
class GenreChips extends StatelessWidget {
  final List<Genre> genres;
  final String? selectedGenreId;
  final ValueChanged<String?> onGenreSelected;
  final bool isDark;

  const GenreChips({
    super.key,
    required this.genres,
    required this.selectedGenreId,
    required this.onGenreSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (genres.isEmpty) {
      return const SizedBox(height: 60);
    }

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: genres.length,
        itemBuilder: (context, index) {
          final genre = genres[index];
          final isSelected = selectedGenreId == genre.id;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(genre.name),
              selected: isSelected,
              onSelected: (selected) {
                onGenreSelected(selected ? genre.id : null);
              },
              selectedColor: const Color(0xFF6366F1),
              backgroundColor:
                  isDark ? const Color(0xFF1E293B) : Colors.white,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }
}

