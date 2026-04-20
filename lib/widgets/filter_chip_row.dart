import 'package:flutter/material.dart';

class FilterChipRow extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final Function(String) onSelected;

  const FilterChipRow({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  IconData _iconFor(String filter) {
    switch (filter) {
      case 'Warkop':
        return Icons.coffee;
      case 'Cafe':
        return Icons.local_cafe;
      case 'Kopi susu':
        return Icons.emoji_food_beverage;
      case 'Buka sekarang':
        return Icons.access_time;
      default:
        return Icons.grid_view;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selected;
          return GestureDetector(
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xffd4722a) : Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xffd4722a) : Colors.white24,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _iconFor(filter),
                    size: 13,
                    color: isSelected ? Colors.white : Colors.white54,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
