import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/utils/haptics.dart';

/// Star rating display
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.starCount = 5,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.spacing = 4,
  });

  final double rating;
  final double maxRating;
  final int starCount;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    // Convert rating to star value (e.g., 8/10 = 4/5 stars)
    final starValue = (rating / maxRating) * starCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        final fillAmount = (starValue - index).clamp(0.0, 1.0);

        return Padding(
          padding: EdgeInsets.only(right: index < starCount - 1 ? spacing : 0),
          child: _Star(
            size: size,
            fillAmount: fillAmount,
            activeColor: activeColor ?? VColors.accentSecondary,
            inactiveColor: inactiveColor ?? VColors.bgSec(context),
          ),
        );
      }),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.size,
    required this.fillAmount,
    required this.activeColor,
    required this.inactiveColor,
  });

  final double size;
  final double fillAmount;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Icon(
            Icons.star,
            size: size,
            color: inactiveColor,
          ),
          ClipRect(
            clipper: _StarClipper(fillAmount),
            child: Icon(
              Icons.star,
              size: size,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarClipper extends CustomClipper<Rect> {
  _StarClipper(this.fillAmount);

  final double fillAmount;

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fillAmount, size.height);
  }

  @override
  bool shouldReclip(_StarClipper oldClipper) {
    return fillAmount != oldClipper.fillAmount;
  }
}

/// Interactive star rating input
class RatingInput extends StatefulWidget {
  const RatingInput({
    super.key,
    required this.onRatingChanged,
    this.initialRating = 0,
    this.maxRating = 5,
    this.starCount = 5,
    this.size = 40,
    this.allowHalfRating = true,
  });

  final ValueChanged<double> onRatingChanged;
  final double initialRating;
  final double maxRating;
  final int starCount;
  final double size;
  final bool allowHalfRating;

  @override
  State<RatingInput> createState() => _RatingInputState();
}

class _RatingInputState extends State<RatingInput> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  void _updateRating(double localX, double totalWidth) {
    final starWidth = totalWidth / widget.starCount;
    final starIndex = (localX / starWidth).floor();
    final positionInStar = (localX % starWidth) / starWidth;

    double newRating;
    if (widget.allowHalfRating) {
      newRating = starIndex + (positionInStar > 0.5 ? 1.0 : 0.5);
    } else {
      newRating = starIndex + 1.0;
    }

    newRating = newRating.clamp(0.0, widget.starCount.toDouble());
    final actualRating = (newRating / widget.starCount) * widget.maxRating;

    if (actualRating != _rating) {
      setState(() => _rating = actualRating);
      VHaptics.rating();
      widget.onRatingChanged(actualRating);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        _updateRating(details.localPosition.dx, context.size!.width);
      },
      onHorizontalDragUpdate: (details) {
        _updateRating(details.localPosition.dx, context.size!.width);
      },
      child: RatingStars(
        rating: _rating,
        maxRating: widget.maxRating,
        starCount: widget.starCount,
        size: widget.size,
        spacing: 8,
      ),
    );
  }
}

/// Compact rating badge
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.rating,
    this.size = RatingBadgeSize.medium,
  });

  final double rating;
  final RatingBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final (iconSize, fontSize, padding) = switch (size) {
      RatingBadgeSize.small => (12.0, 11.0, const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
      RatingBadgeSize.medium => (14.0, 13.0, const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
      RatingBadgeSize.large => (16.0, 15.0, const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
    };

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: iconSize,
            color: VColors.accentSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum RatingBadgeSize { small, medium, large }
