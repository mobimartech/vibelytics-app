import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/shadows.dart';
import '../../core/utils/haptics.dart';

/// Reaction/rating picker for photos
class ReactionPicker extends StatefulWidget {
  const ReactionPicker({
    super.key,
    required this.onRatingSelected,
    this.initialRating,
    this.maxRating = 5,
  });

  final ValueChanged<int> onRatingSelected;
  final int? initialRating;
  final int maxRating;

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker> {
  int? _selectedRating;
  int? _hoveredRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
  }

  void _selectRating(int rating) {
    setState(() => _selectedRating = rating);
    VHaptics.rating();
    widget.onRatingSelected(rating);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: VColors.card(context),
        borderRadius: VRadii.xlRadius,
        boxShadow: VShadow.level2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'photo.rate_this'.tr(),
            style: VType.h3.copyWith(color: VColors.text(context)),
          ),
          const SizedBox(height: 20),
          // Rating buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(widget.maxRating, (index) {
              final rating = index + 1;
              final isSelected = _selectedRating == rating;
              final isHovered = _hoveredRating == rating;
              final isHighlighted = isSelected ||
                  isHovered ||
                  (_hoveredRating != null && rating <= _hoveredRating!);

              return GestureDetector(
                onTap: () => _selectRating(rating),
                onTapDown: (_) => setState(() => _hoveredRating = rating),
                onTapUp: (_) => setState(() => _hoveredRating = null),
                onTapCancel: () => setState(() => _hoveredRating = null),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? VColors.accentPrimary
                        : isHighlighted
                            ? VColors.accentPrimary.withValues(alpha: 0.2)
                            : VColors.bgSec(context),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected || isHighlighted
                          ? VColors.accentPrimary
                          : VColors.borderSubtle,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$rating',
                      style: VType.labelSm.copyWith(
                        color: isSelected
                            ? Colors.white
                            : isHighlighted
                                ? VColors.accentPrimary
                                : VColors.textSec(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (_selectedRating != null) ...[
            const SizedBox(height: 16),
            Text(
              _getRatingLabel(_selectedRating!),
              style: VType.label.copyWith(color: VColors.textSec(context)),
            ),
          ],
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1: return 'photo.rating_1'.tr();
      case 2: return 'photo.rating_2'.tr();
      case 3: return 'photo.rating_3'.tr();
      case 4: return 'photo.rating_4'.tr();
      case 5: return 'photo.rating_5'.tr();
      default: return '';
    }
  }
}

/// Compact inline rating picker
class InlineRatingPicker extends StatefulWidget {
  const InlineRatingPicker({
    super.key,
    required this.onRatingSelected,
    this.initialRating,
    this.maxRating = 5,
  });

  final ValueChanged<int> onRatingSelected;
  final int? initialRating;
  final int maxRating;

  @override
  State<InlineRatingPicker> createState() => _InlineRatingPickerState();
}

class _InlineRatingPickerState extends State<InlineRatingPicker> {
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.maxRating, (index) {
        final rating = index + 1;
        final isSelected = _selectedRating != null && rating <= _selectedRating!;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedRating = rating);
            VHaptics.rating();
            widget.onRatingSelected(rating);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isSelected ? Icons.star : Icons.star_outline,
              size: 28,
              color: isSelected
                  ? VColors.accentSecondary
                  : VColors.textTer(context),
            ),
          ),
        );
      }),
    );
  }
}

/// Quick emoji reactions
class QuickReactions extends StatelessWidget {
  const QuickReactions({
    super.key,
    required this.onReactionSelected,
    this.reactions = const ['👍', '❤️', '🔥', '😍', '⭐'],
  });

  final ValueChanged<String> onReactionSelected;
  final List<String> reactions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: VColors.card(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: VShadow.level2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: reactions.map((emoji) {
          return GestureDetector(
            onTap: () {
              VHaptics.light();
              onReactionSelected(emoji);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
