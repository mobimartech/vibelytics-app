import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/shadows.dart';

/// Data tile for displaying stats and metrics
class DataTile extends StatelessWidget {
  const DataTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.trend,
    this.trendValue,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final TrendDirection? trend;
  final String? trendValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VColors.card(context),
          borderRadius: VRadii.lgRadius,
          boxShadow: VShadow.level1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: VColors.textTer(context),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: VType.caption.copyWith(
                      color: VColors.textSec(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Value
            Text(
              value,
              style: VType.kpiLarge.copyWith(
                color: VColors.text(context),
              ),
            ),
            // Trend or subtitle
            if (trend != null && trendValue != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    trend == TrendDirection.up
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 14,
                    color: trend == TrendDirection.up
                        ? VColors.success
                        : VColors.error,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    trendValue!,
                    style: VType.caption.copyWith(
                      color: trend == TrendDirection.up
                          ? VColors.success
                          : VColors.error,
                    ),
                  ),
                ],
              ),
            ] else if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: VType.caption.copyWith(
                  color: VColors.textTer(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum TrendDirection { up, down }

/// Row of data tiles with equal spacing
class DataTileRow extends StatelessWidget {
  const DataTileRow({
    super.key,
    required this.tiles,
  });

  final List<DataTile> tiles;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: tiles.map((tile) {
        final isLast = tile == tiles.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: tile,
          ),
        );
      }).toList(),
    );
  }
}
