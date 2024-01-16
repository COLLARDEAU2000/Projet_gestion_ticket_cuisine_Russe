class SubCategory {
  final int id;
  final String name;
  final int categoryId;

  SubCategory({
    required this.id,
    required this.name,
    required this.categoryId,
  });
// Ajoutez cette méthode à votre classe SubCategory
  factory SubCategory.fromMap(Map<String, dynamic> map) {
    return SubCategory(
      id: map['id'] as int,
      name: map['name'] as String,
      categoryId: map['categoryId'] as int,
    );
  }
  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      categoryId: json['categoryId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
    };
  }
}
