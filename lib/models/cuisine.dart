// Cuisine.dart
import 'package:grinlintsa/models/category_cuisine.dart';
import 'package:grinlintsa/models/cook.dart'; 

class Cuisine {
  int id;
  String name;
  List<Cook> cookList;
  List<Categorie> categoryList; // Ajoutez la liste des catégories

  Cuisine({
    required this.id,
    required this.name,
    this.cookList = const [],
    this.categoryList = const [], // Initialisez la liste des catégories
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Cuisine.fromMap(Map<String, dynamic> map) {
    return Cuisine(
      id: map['id'],
      name: map['name'],
      cookList: [], // Initialisez la liste de cuisiniers à partir des données de la base de données si nécessaire
      categoryList: [], // Initialisez la liste de catégories à partir des données de la base de données si nécessaire
    );
  } 
}
