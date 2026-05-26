/// Credit transaction model
class CreditTransaction {
  final int id;
  final int amount;
  final String type; // 'earned', 'spent', 'purchased', 'referral', 'bonus'
  final String description;
  final DateTime createdAt;
  final int balanceAfter;

  const CreditTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    required this.balanceAfter,
  });

  /// Check if this is a positive transaction (earned credits)
  bool get isPositive => amount > 0;

  /// Check if this is a negative transaction (spent credits)
  bool get isNegative => amount < 0;

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'],
      amount: json['amount'],
      type: json['type'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      balanceAfter: json['balance_after'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type,
        'description': description,
        'created_at': createdAt.toIso8601String(),
        'balance_after': balanceAfter,
      };
}
