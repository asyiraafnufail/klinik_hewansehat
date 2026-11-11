class ServiceModel {
  final String id;
  final String name;
  final String category;
  final String? description;
  final double price;
  final int durationMinutes;
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.price,
    required this.durationMinutes,
    this.isActive = true,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    final rawDuration = json['duration_minutes'];
    return ServiceModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? 'Umum',
      description: json['description'] as String?,
      price: rawPrice is num
          ? rawPrice.toDouble()
          : (double.tryParse(rawPrice?.toString() ?? '') ?? 0),
      durationMinutes: rawDuration is num
          ? rawDuration.toInt()
          : (int.tryParse(rawDuration?.toString() ?? '') ?? 30),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'duration_minutes': durationMinutes,
      'is_active': isActive,
    };
  }
}
