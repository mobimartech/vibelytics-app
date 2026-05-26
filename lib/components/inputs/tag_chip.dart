import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';

/// Tag chip for categories and filters
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? VColors.accentPrimary
              : VColors.bgSec(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? VColors.accentPrimary
                : VColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? VColors.textInverse
                    : VColors.textSec(context),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: VType.label.copyWith(
                color: isSelected
                    ? VColors.textInverse
                    : VColors.textSec(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Selectable tag chip group
class TagChipGroup extends StatelessWidget {
  const TagChipGroup({
    super.key,
    required this.tags,
    required this.selectedTags,
    required this.onTagSelected,
    this.scrollable = true,
  });

  final List<String> tags;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagSelected;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final chips = tags.map((tag) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TagChip(
          label: tag,
          isSelected: selectedTags.contains(tag),
          onTap: () => onTagSelected(tag),
        ),
      );
    }).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }
}
