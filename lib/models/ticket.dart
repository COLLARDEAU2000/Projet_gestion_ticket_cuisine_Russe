class Ticket {
  String id;
  int cuisineId;
  int ingredientId;
  int cookId;
  DateTime dateCreation;
  DateTime? dateIntermediaire;
  DateTime datePeremption;
  bool isPerime;
  int temperature;
  int quantite;
  String notification;
  String etatAvantApresOuverture;

  Ticket({
    required this.id,
    required this.cuisineId,
    required this.ingredientId,
    required this.cookId,
    required this.dateCreation,
    required this.dateIntermediaire,
    required this.datePeremption,
    required this.isPerime,
    required this.temperature,
    required this.quantite,
    required this.notification,
    required this.etatAvantApresOuverture,
  });

  // Setters for each attribute
  set setId(String value) => id = value;
  set setCuisineId(int value) => cuisineId = value;
  set setIngredientId(int value) => ingredientId = value;
  set setCookId(int value) => cookId = value;
  set setDateCreation(DateTime value) => dateCreation = value;
  set setDateIntermediaire(DateTime? value) => dateIntermediaire = value;
  set setDatePeremption(DateTime value) => datePeremption = value;
  set setIsPerime(bool value) => isPerime = value;
  set setTemperature(int value) => temperature = value;
  set setQuantite(int value) => quantite = value;
  set setNotification(String value) => notification = value;
  set setEtatAvantApresOuverture(String value) => etatAvantApresOuverture = value;

  // Rest of your class...
   static String generateId(
      int cuisineId, DateTime dateCreation, DateTime datePeremption) {
    const code = 'GR';
    final dateCreationString =
        dateCreation.toIso8601String().substring(0, 10);
    final datePeremptionString =
        datePeremption.toIso8601String().substring(0, 10);
    return '$code-$cuisineId-$dateCreationString-$datePeremptionString';
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? '',
      cuisineId: json['cuisineId'] ?? 0,
      ingredientId: json['ingredientId'] ?? 0,
      cookId: json['cookId'] ?? 0,
      dateCreation: DateTime.parse(json['dateCreation'] ?? ''),
      dateIntermediaire: json['dateIntermediaire'] != null
          ? DateTime.parse(json['dateIntermediaire'])
          : null,
      datePeremption: DateTime.parse(json['datePeremption'] ?? ''),
      isPerime: json['isPerime'] ?? false,
      temperature: json['temperature'] ?? 0,
      quantite: json['quantite'] ?? 0,
      notification: json['notification'] ?? '',
      etatAvantApresOuverture: json['etatAvantApresOuverture'] ?? '',
    );
  }

  @override
  String toString() {
    return 'Ticket{id: $id, cuisineId: $cuisineId, ingredientId: $ingredientId, ...}';
  }

  // toJson() method remains the same
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cuisineId': cuisineId,
      'ingredientId': ingredientId,
      'cookId': cookId,
      'dateCreation': dateCreation.toIso8601String(),
      'dateIntermediaire': dateIntermediaire?.toIso8601String(),
      'datePeremption': datePeremption.toIso8601String(),
      'isPerime': isPerime,
      'temperature': temperature,
      'quantite': quantite,
      'notification': notification,
      'etatAvantApresOuverture': etatAvantApresOuverture,
    };
  }
}
