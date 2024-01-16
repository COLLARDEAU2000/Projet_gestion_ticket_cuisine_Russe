// cook.dart
class Cook {
  int? id;
  String name;
  String speciality;
  int cuisineId;

  // Constructeur de la classe Cook
  Cook({
    this.id,
    required this.name,
    required this.speciality,
    required this.cuisineId,
  });

  // Convertit l'objet Cook en une map pour le stockage dans la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'speciality': speciality,
      'cuisineId': cuisineId,
    };
  }

  // Crée un objet Cook à partir d'une map stockée dans la base de données
  factory Cook.fromMap(Map<String, dynamic> map) {
    return Cook(
      id: map['id'],
      name: map['name'],
      speciality: map['speciality'],
      cuisineId: map['cuisineId'],
    );
  }
}
