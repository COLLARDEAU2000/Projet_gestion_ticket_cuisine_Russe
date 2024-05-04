import 'package:dart_date/dart_date.dart';

class Calculator {
  static List<String> calculateDate(String time, int indicator) {
    List<String> dates = [];
    List<dynamic>? resultat = normalisationTemps(time);

    if (indicator == 0) {
      dates = ajouteDeuxDates(resultat);
    } else if (indicator == 1) {
      dates = ajouteTroisDates(resultat);
    }

    return dates;
  }

  static List<String> ajouteDeuxDates(List<dynamic>? time) {
    DateTime now = DateTime.now();
    DateTime firstDate = now;
    DateTime? secondDate = now;
    String mot = time![1];
    int nombre = time[0];
    if (mot == 'jours') {
      secondDate = secondDate.addDays(nombre);
    } else if (mot == 'heures') {
      secondDate = secondDate.addHours(nombre);
    } else if (mot == 'mois') {
      secondDate = secondDate.addMonths(nombre);
    } else if (mot == 'annees') {
      secondDate = secondDate.addYears(nombre);
    }

    return [
      firstDate.format('dd MM y, h:mm:ss'),
      secondDate.format('dd MM y, h:mm:ss')
    ];
  }

  static List<String> ajouteTroisDates(List<dynamic>? time) {
    DateTime now = DateTime.now();
    DateTime firstDate = now;
    DateTime secondDate = now.addHours(
        24); 
    // Ajouter 24 heures à la date actuelle pour obtenir la deuxième date
    //on a produit dans cuisine qui ajoute 3 h pour la deuxieme date
    //ce meme produit ajoute 1 journe a sa 3 eme date qui la premiere date + 1 jour
    // ce produit est dans la cuisine pizza

    String mot = time![1];
    int nombre = time[0];
    // Calculer la troisième date en fonction de l'unité de temps spécifiée
    DateTime thirdDate = now;
    if (mot == 'jours') {
      thirdDate = now.addDays(nombre);
    } else if (mot == 'heures') {
      thirdDate = now.addHours(nombre);
    } else if (mot == 'mois') {
      thirdDate = now.addMonths(nombre);
    } else if (mot == 'annees') {
      thirdDate = now.addYears(nombre);
    }

    return [
      firstDate.format('dd MM y, h:mm:ss'),
      secondDate.format('dd MM y, h:mm:ss'),
      thirdDate.format('dd MM y, h:mm:ss')
    ];
  }

  static List<dynamic>? normalisationTemps(String time) {
    List<dynamic>? resultat = [];
    // Expression régulière pour récupérer un nombre ou un chiffre suivi d'un mot
    RegExp regex = RegExp(r'(\d+)\s*(\w+)');
    // Recherche du premier nombre ou chiffre dans la chaîne de caractères
    Match? match = regex.firstMatch(time);

    // Vérifie si un nombre ou un chiffre a été trouvé
    if (match != null) {
      // Récupère la chaîne de caractères correspondant au nombre ou chiffre
      String? nombreChaine = match.group(1);

      // Convertit la chaîne de caractères en entier
      int? nombre = int.tryParse(nombreChaine ?? '');
      resultat.add(nombre);

      // Récupère le mot qui suit le nombre ou chiffre
      String? mot = match.group(2);
      resultat.add(mot);
    }
    return resultat;
  }
}
