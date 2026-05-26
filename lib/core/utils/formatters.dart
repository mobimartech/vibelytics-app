import 'package:easy_localization/easy_localization.dart';

/// Number and date formatters for Vibelytics
abstract class VFormat {
  VFormat._();

  // ═══════════════════════════════════════════════════════════════════════════
  // NUMBER FORMATTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Format large numbers with K/M suffix
  /// e.g., 1200 -> "1.2K", 1500000 -> "1.5M"
  static String compactNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Format credit balance
  /// e.g., 47 -> "47", 1000 -> "1,000"
  static String credits(int amount) {
    if (amount >= 1000) {
      return NumberFormat('#,###').format(amount);
    }
    return amount.toString();
  }

  /// Format rating value (always 1 decimal)
  /// e.g., 4.0 -> "4.0", 4.75 -> "4.8"
  static String rating(double value) {
    return value.toStringAsFixed(1);
  }

  /// Format percentage
  /// e.g., 0.75 -> "75%", 0.333 -> "33%"
  static String percentage(double value) {
    return '${(value * 100).round()}%';
  }

  /// Format currency
  /// e.g., 9.99 -> "$9.99"
  static String currency(double amount, {String symbol = r'$'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATE FORMATTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Format relative time
  /// e.g., "2m ago", "3h ago", "Yesterday", "Jan 15"
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'common.just_now'.tr();
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'common.yesterday'.tr();
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  /// Format as "Member since Jan 2025"
  static String memberSince(DateTime dateTime) {
    return DateFormat('MMM yyyy').format(dateTime);
  }

  /// Format full date
  /// e.g., "January 15, 2025"
  static String fullDate(DateTime dateTime) {
    return DateFormat('MMMM d, yyyy').format(dateTime);
  }

  /// Format time
  /// e.g., "3:45 PM"
  static String time(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STRING FORMATTING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mask phone number
  /// e.g., "+1234567890" -> "+1***890"
  static String maskedPhone(String phone) {
    if (phone.length <= 6) return phone;
    final start = phone.substring(0, 2);
    final end = phone.substring(phone.length - 3);
    return '$start***$end';
  }

  /// Mask email
  /// e.g., "test@email.com" -> "t***@email.com"
  static String maskedEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return email;
    final name = parts[0];
    final domain = parts[1];
    return '${name[0]}***@$domain';
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
