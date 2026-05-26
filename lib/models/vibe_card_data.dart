/// Vibe Card data model for shareable trading card
class VibeCardData {
  final String username;
  final String photoUrl;
  final String rarity; // 'common', 'rare', 'epic', 'legendary'
  final Map<String, int> stats; // Mystery, Aesthetic, Energy, Chaos, Warmth

  const VibeCardData({
    required this.username,
    required this.photoUrl,
    required this.rarity,
    required this.stats,
  });

  /// Get stat value by name
  int getStat(String name) => stats[name] ?? 0;

  /// Get mystery stat
  int get mystery => stats['mystery'] ?? 0;

  /// Get aesthetic stat
  int get aesthetic => stats['aesthetic'] ?? 0;

  /// Get energy stat
  int get energy => stats['energy'] ?? 0;

  /// Get chaos stat
  int get chaos => stats['chaos'] ?? 0;

  /// Get warmth stat
  int get warmth => stats['warmth'] ?? 0;

  /// Get rarity display text
  String get rarityDisplay {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return 'LEGENDARY AURA ✨';
      case 'epic':
        return 'EPIC AURA ✨';
      case 'rare':
        return 'RARE AURA ✨';
      default:
        return 'COMMON AURA';
    }
  }

  factory VibeCardData.fromJson(Map<String, dynamic> json) {
    return VibeCardData(
      username: json['username'],
      photoUrl: json['photo_url'],
      rarity: json['rarity'] ?? 'common',
      stats: Map<String, int>.from(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'photo_url': photoUrl,
        'rarity': rarity,
        'stats': stats,
      };
}
