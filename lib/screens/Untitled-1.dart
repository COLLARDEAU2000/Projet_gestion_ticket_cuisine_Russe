// ignore_for_file: file_names

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:grinlintsa/models/cook.dart';
import 'package:grinlintsa/models/cuisine.dart';
import 'package:grinlintsa/models/category_cuisine.dart';
import 'package:grinlintsa/models/sub_category.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'x_database.db');

      Database database = await openDatabase(
        path,
        version: 2, // Mettez à jour la version de la base de données
        onCreate: (Database db, int version) async {
          await db.execute('''
          CREATE TABLE Cuisines (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL
          )
        ''');

          await db.execute('''
          CREATE TABLE Cooks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            speciality TEXT NOT NULL,
            cuisineId INTEGER NOT NULL,
            FOREIGN KEY(cuisineId) REFERENCES Cuisines(id)
          )
        ''');

          await db.execute('''
          CREATE TABLE Categories (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            cuisineId INTEGER NOT NULL,
            FOREIGN KEY(cuisineId) REFERENCES Cuisines(id)
          )
        ''');

          await db.execute('''
          CREATE TABLE SubCategories (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            categoryId INTEGER NOT NULL,
            FOREIGN KEY(categoryId) REFERENCES Categories(id)
          )
        ''');

          await db.execute('''
          CREATE TABLE Temperatures (
            id INTEGER PRIMARY KEY,
            ouvert INTEGER NOT NULL,
            categoryId INTEGER NOT NULL,
            temperature TEXT NOT NULL,
            subCategoryId INTEGER NOT NULL,
            dureeDeConservation TEXT NOT NULL,
            indicateur INTEGER NOT NULL,
            FOREIGN KEY(categoryId) REFERENCES Categories(id)
            FOREIGN KEY(subCategoryId) REFERENCES SubCategories(id)
          )
        ''');

          // Créer la table AppInfo
          await db.execute('''
          CREATE TABLE IF NOT EXISTS AppInfo (
            version INTEGER
          )
        ''');

          // Insérer la version actuelle dans la table AppInfo
          await db.rawInsert('INSERT INTO AppInfo (version) VALUES (?)', [2]);

          if (kDebugMode) {
            print('Tables créées avec succès');
          }
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          // Logique de mise à niveau si la version change
          if (oldVersion == 1 && newVersion == 2) {
            // Ajouter des étapes de mise à niveau si nécessaire
          }
        },
      );

      _database = database;
      return database;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation de la base de données : $e');
      }
      rethrow;
    }
  }

  //PARTIE DES METHODES DE CUISINES

  Future<int> insertCuisine(Cuisine cuisine) async {
    Database db = await database;
    return await db.insert('Cuisines', cuisine.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> initializeData() async {
    try {
      Database db = await database;

      List<Map<String, dynamic>> initialCuisineData = [
        {
          "id": 1,
          "name": "ШАУРМА",
        },
        {
          "id": 2,
          "name": "ПИЦЦА",
        },
        {
          "id": 3,
          "name": "ЯПОНИЯ",
        },
        {
          "id": 4,
          "name": "ОВОЩНОЙ ЦЕХ",
        }
      ];

      await db.transaction((txn) async {
        Batch batch = txn.batch();
        for (Map<String, dynamic> data in initialCuisineData) {
          batch.rawInsert(
              'INSERT OR IGNORE INTO Cuisines (id, name) VALUES (?, ?)',
              [data['id'], data['name']]);
        }
        await batch.commit();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation des données : $e');
      }
      rethrow;
    }
  }

  Future<List<Cuisine>> getCuisines() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('Cuisines');
    return List.generate(maps.length, (i) {
      return Cuisine(
        id: maps[i]['id'],
        name: maps[i]['name'],
        cookList: [],
        categoryList: [],
      );
    });
  }

  //PARTIE DES METHODES DES CUISINIERS

  //charger les cooks d'une cuisine
  // Récupérer la liste des cooks pour une cuisine spécifique depuis la base de données
  Future<List<Cook>> getCooks(Cuisine cuisine) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db
        .query('Cooks', where: 'cuisineId = ?', whereArgs: [cuisine.id]);
    return List.generate(maps.length, (i) {
      return Cook(
        id: maps[i]['id'],
        name: maps[i]['name'],
        speciality: maps[i]['speciality'],
        cuisineId: maps[i]['cuisineId'],
      );
    });
  }

  // inserer un cook dans une cuisine
  // Méthode pour insérer un cook dans la base de données
  Future<int> insertCook(Cook cook) async {
    Database db = await database;
    // Utilisez la méthode insert sans spécifier la colonne ID pour permettre l'auto-incrémentation
    return await db.insert('Cooks', cook.toMap());
  }

  // supprimer un cook d'une cuisine
  // Supprimer le  cook d'une cuisine en fonction de son ID
  Future<int> deleteCook(Cuisine cuisine, Cook cook) async {
    Database db = await database;
    return await db.delete('Cooks',
        where: 'cuisineId = ? AND id = ?', whereArgs: [cuisine.id, cook.id]);
  }

  // PARTIE POUR LES CATEGORIES
  // Insérer une catégorie dans la base de données
  Future<int> insertCategory(Categorie category) async {
    Database db = await database;
    return await db.insert('Categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Charger les catégories pour une cuisine spécifique depuis la base de données
  Future<List<Categorie>> getCategories(Cuisine cuisine) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db
        .query('Categories', where: 'cuisineId = ?', whereArgs: [cuisine.id]);
    return List.generate(maps.length, (i) {
      return Categorie.fromMap(maps[i]);
    });
  }

  // Méthode pour initialiser les catégories au lancement de la base de données
  Future<void> initializeCategories() async {
    try {
      Database db = await database;

      List<Map<String, dynamic>> initialCategoryData = [
        {"id": 1, "name": "СОУСЫ", "cuisineId": 1},
      ];

      await db.transaction((txn) async {
        Batch batch = txn.batch();
        for (Map<String, dynamic> data in initialCategoryData) {
          batch.rawInsert(
              'INSERT OR IGNORE INTO Categories (id, name, cuisineId) VALUES (?, ?, ?)',
              [data['id'], data['name'], data['cuisineId']]);
        }
        await batch.commit();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation des catégories : $e');
      }
      rethrow;
    }
  }

  //PARTIE SUBCATEGORIE

  Future<List<SubCategory>> getSubCategories(int categoryId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'SubCategories',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );

    return List.generate(maps.length, (i) {
      return SubCategory(
        id: maps[i]['id'],
        name: maps[i]['name'],
        categoryId: maps[i]['categoryId'],
      );
    });
  }

  Future<void> initializeSubCategories() async {
    try {
      Database db = await database;

      // Données initiales des sous-catégories
      List<Map<String, dynamic>> initialSubCategoryData = [
        {"id": 1, "name": "Томаты", "categoryId": 21},
      ];

      await db.transaction((txn) async {
        Batch batch = txn.batch();
        for (Map<String, dynamic> data in initialSubCategoryData) {
          batch.rawInsert(
              'INSERT OR IGNORE INTO Subcategories (id, name,categoryId) VALUES (?, ?, ?)',
              [data['id'], data['name'], data['categoryId']]);
        }
        await batch.commit();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation des données : $e');
      }
      rethrow;
    }
  }

  //PARTIE TEMPERATURE
  //Charger les données initiales dans la table Temperature
  Future<void> initializeTemperatures() async {
    try {
      Database db = await database;

      List<Map<String, dynamic>> initialTemperatureData = [
        {
          "id": 1,
          "ouvert": false,
          "categoryId": 10,
          "temperature": "-18°С",
          "subCategoryId": 41,
          "Duree de concervation": "180 jours",
          "indicateur": true
        },
        {
          "id": 2,
          "ouvert": true,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 38,
          "Duree de concervation": "48 jours",
          "indicateur": false
        },
        {
          "id": 3,
          "ouvert": true,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 39,
          "Duree de concervation": "48 jours",
          "indicateur": false
        },
        {
          "id": 4,
          "ouvert": true,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 40,
          "Duree de concervation": "48 jours",
          "indicateur": false
        },
        {
          "id": 5,
          "ouvert": true,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 41,
          "Duree de concervation": "48 jours",
          "indicateur": false
        },
      ];
      await db.transaction((txn) async {
        Batch batch = txn.batch();
        for (Map<String, dynamic> data in initialTemperatureData) {
          batch.rawInsert(
            'INSERT OR IGNORE INTO Temperatures (id,ouvert, categoryId,temperature,subCategoryId,dureeDeConservation, indicateur) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [
              data['id'],
              data['ouvert'],
              data['categoryId'],
              data['temperature'],
              data['subCategoryId'],
              data['dureeDeConservation'],
              data['indicateur']
            ],
          );
        }
        await batch.commit();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de l\'initialisation des données : $e');
      }
      rethrow;
    }
  }
  
}
