/// Tag model for photo categorization
class Tag {
  final int id;
  final String name;
  final String slug;
  final int displayOrder;
  final int photoCount;

  const Tag({
    required this.id,
    required this.name,
    required this.slug,
    required this.displayOrder,
    required this.photoCount,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      displayOrder: json['display_order'] ?? 0,
      photoCount: json['photo_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'display_order': displayOrder,
        'photo_count': photoCount,
      };
}
