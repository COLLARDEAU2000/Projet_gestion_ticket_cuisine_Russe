class Categorie {
  final int id;
  final String name;
  final int cuisineId;

  Categorie({
    required this.id,
    required this.name,
    required this.cuisineId,
  });

  // Convertir un Categorie en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cuisineId': cuisineId,
    };
  }

  // Créer un Categorie à partir d'un Map
  factory Categorie.fromMap(Map<String, dynamic> map) {
    return Categorie(
      id: map['id'],
      name: map['name'],
      cuisineId: map['cuisineId'],
    );
  }
}
