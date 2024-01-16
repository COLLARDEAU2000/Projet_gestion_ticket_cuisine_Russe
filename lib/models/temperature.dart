class Temperature {
  final int id;
  final int ouvert;
  final int categoryId;
  final String temperature;
  final int subCategoryId;
  final String dureeDeConservation;
  final int indicateur;

  Temperature({
    required this.id,
    required this.ouvert,
    required this.categoryId,
    required this.temperature,
    required this.subCategoryId,
    required this.dureeDeConservation,
    required this.indicateur,
  });

  factory Temperature.fromJson(Map<String, dynamic> json) {
    return Temperature(
      id: json['id'] ?? 0,
      ouvert: json['ouvert'] ?? 0,
      categoryId: json['categoryId'] ?? 0,
      temperature: json['temperature'] ?? '',
      subCategoryId: json['subCategoryId'] ?? 0,
      dureeDeConservation: json['dureeDeConservation'] ?? '',
      indicateur: json['indicateur'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ouvert': ouvert,
      'categoryId': categoryId,
      'temperature': temperature,
      'subCategoryId': subCategoryId,
      'dureeDeConservation': dureeDeConservation,
      'indicateur': indicateur,
    };
  }
}
