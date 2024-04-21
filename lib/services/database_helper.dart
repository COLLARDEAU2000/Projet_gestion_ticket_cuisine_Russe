// ignore_for_file: unnecessary_null_comparison, duplicate_ignore
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:grinlintsa/models/cook.dart';
import 'package:grinlintsa/models/cuisine.dart';
import 'package:grinlintsa/models/category_cuisine.dart';
import 'package:grinlintsa/models/sub_category.dart';
import 'package:grinlintsa/models/temperature.dart';
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
      String path = join(documentsDirectory.path, 'opex_database.db');

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
            ouvert INTEGER ,            
            categoryId INTEGER ,
            temperature TEXT NOT NULL,
            subCategoryId INTEGER ,
            dureeDeConservation TEXT NOT NULL,
            indicateur INTEGER,
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
        {"id": 10, "name": "МЯСО", "cuisineId": 1},
        {"id": 11, "name": "ГАСТРОНОМИЯ", "cuisineId": 1},
        {"id": 12, "name": "КОНСЕРВАЦИЯ", "cuisineId": 1},
        {"id": 13, "name": "ЗАМОРОЗКА", "cuisineId": 1},
        {"id": 14, "name": "СОУСЫ И ЗАМЕСЫ", "cuisineId": 1},
        {"id": 16, "name": "МЯСНАЯ ГАСТРОНОМИЯ", "cuisineId": 1},
        {"id": 17, "name": "ЯИЧНЫЕ ПРОДУКТЫ", "cuisineId": 1},
        {
          "id": 19,
          "name": "ПОЛУФАБРИКАТЫ ОВОЩНЫЕ МАРИНОВАННЫЕ",
          "cuisineId": 1
        },
        {
          "id": 20,
          "name": "ПОЛУФАБРИКАТЫ ПОСЛЕ ТЕРМИЧЕСКОЙ ОБРАБОТКИ",
          "cuisineId": 1
        },
        {"id": 21, "name": "ОВОЩИ", "cuisineId": 1},
        {"id": 22, "name": "БАКАЛЕЯ", "cuisineId": 1},
        {"id": 23, "name": "МЯСНАЯ ГАСТРОНОМИЯ", "cuisineId": 2},
        {"id": 24, "name": "СЫРНАЯ ГАСТРОНОМИЯ", "cuisineId": 2},
        {"id": 25, "name": "КОНСЕРВАЦИ", "cuisineId": 2},
        {"id": 30, "name": "КОНСЕРВАЦИ", "cuisineId": 2},
        {"id": 26, "name": "МЯСО", "cuisineId": 2},
        {"id": 27, "name": "Соусы", "cuisineId": 2},
        {"id": 28, "name": "БАКАЛЕЯ", "cuisineId": 2},
        {"id": 29, "name": "МОРЕПРОДУКТЫ", "cuisineId": 2},
        {"id": 31, "name": "МЯСНАЯ ГАСТРОНОМИЯ", "cuisineId": 2},
        {"id": 32, "name": "СЫРНАЯ ГАСТРОНОМИЯ", "cuisineId": 2},
        {"id": 35, "name": "СОУСЫ ПОЛУФАБРИКАТ", "cuisineId": 2},
        {"id": 36, "name": "ОВОЩИ", "cuisineId": 2},
        {
          "id": 37,
          "name": "ПОЛУФАБРИКАТЫ ОВОЩНЫЕ МАРИНОВАННЫЕ",
          "cuisineId": 2
        },
        {"id": 38, "name": "ТЕСТО ПОЛУФАБРИКАТ", "cuisineId": 2},
        {
          "id": 39,
          "name": "ПОЛУФАБРИКАТЫ ПОСЛЕ ТЕРМИЧЕСКОЙ ОБРАБОТКИ",
          "cuisineId": 2
        },
        {"id": 60, "name": "Яичные продукты", "cuisineId": 2},
        {"id": 41, "name": "МЯСНАЯ ГАСТРОНОМИЯ", "cuisineId": 3},
        {"id": 42, "name": "СЫР", "cuisineId": 3},
        {"id": 43, "name": "МОРЕПРОДУКТЫ", "cuisineId": 3},
        {"id": 44, "name": "СОУСЫ", "cuisineId": 3},
        {"id": 45, "name": "БАКАЛЕЯ", "cuisineId": 3},
        {"id": 46, "name": "КОНСЕРВАЦИЯ", "cuisineId": 3},
        {"id": 47, "name": "ЛАПША", "cuisineId": 3},
        {"id": 48, "name": "МЯСО", "cuisineId": 3},
        {"id": 49, "name": "ЗАМАРОЖЕННЫЕ ПОЛУФАБРИКАТ", "cuisineId": 3},
        {"id": 50, "name": "ЗАМОРОЗКА", "cuisineId": 3},
        {"id": 51, "name": "ДЕСЕРТЫ", "cuisineId": 3},
        {"id": 52, "name": "СОУСЫ ПОЛУФАБРИКАТЫ", "cuisineId": 3},
        {"id": 53, "name": "ТЕСТО", "cuisineId": 3},
        {"id": 54, "name": "ОВОЩИ и ФРУКТЫ", "cuisineId": 3},
        {"id": 55, "name": "ЯЙЦО", "cuisineId": 3},
        {"id": 56, "name": "ЗАМЕСЫ на РОЛЛЫ", "cuisineId": 3},
        {"id": 57, "name": "ЗАМЕСЫ на СЫРНЫЕ ШАРИКИ", "cuisineId": 3},
        {
          "id": 58,
          "name": "ПОЛУФАБРИКАТЫ ПОСЛЕ ТЕРМИЧЕСКОЙ ОБРАБОТКИ",
          "cuisineId": 3
        },
        {"id": 59, "name": "HEOБРАБОТАННЫЕ ОВОЩИ И ФРУКТЫ.", "cuisineId": 4},
        {"id": 60, "name": "OБРАБОТАННЫЕ ОВОЩИ И ФРУКТЫ.", "cuisineId": 4}
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
  
  static Future<List<SubCategory>> getSubCategoriesByIds(List<int> subCategoryIds) async {
    try {
      Database db = await _instance.database;

      // Requête pour récupérer les sous-catégories en fonction des IDs fournis
      List<Map<String, dynamic>> maps = await db.query(
        'SubCategories',
        where: 'id IN (${subCategoryIds.join(",")})',
      );

      // Convertir les résultats en objets SubCategorie
      List<SubCategory> subCategories = List.generate(maps.length, (i) {
        return SubCategory.fromJson(maps[i]);
      });

      return subCategories;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des sous-catégories par IDs : $e');
      }
      rethrow;
    }
  }

  static Future<List<Temperature>> getTemperaturesByCategoryId(int categoryId) async {
    try {
      Database db = await _instance.database;

      // Requête pour récupérer les températures en fonction de la catégorie
      List<Map<String, dynamic>> maps = await db.query(
        '>',
        where: 'categoryId = ?',
        whereArgs: [categoryId],
      );

      // Convertir les résultats en objets Temperature
      List<Temperature> temperatures = List.generate(maps.length, (i) {
        return Temperature.fromJson(maps[i]);
      });

      return temperatures;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des températures par catégorie : $e');
      }
      rethrow;
    }
  }

  Future<void> initializeSubCategories() async {
    try {
      Database db = await database;

      // Données initiales des sous-catégories
      List<Map<String, dynamic>> initialSubCategoryData = [
        {"id": 1, "name": "Томаты", "categoryId": 21},
        {"id": 2, "name": "Огурцы", "categoryId": 21},
        {"id": 3, "name": "Лук белый", "categoryId": 21},
        {"id": 4, "name": "Лук красный", "categoryId": 21},
        {"id": 5, "name": " Шампиньоны", "categoryId": 21},
        {"id": 6, "name": "Чеснок очищенный", "categoryId": 21},
        {"id": 7, "name": "Чеснок измельченный", "categoryId": 21},
        {"id": 8, "name": "Капуста", "categoryId": 21},
        {"id": 9, "name": "Перец болгарский", "categoryId": 21},
        {"id": 10, "name": "Морковь", "categoryId": 21},
        {"id": 11, "name": "Лук белый маринованный", "categoryId": 19},
        {"id": 12, "name": "Морковь по-корейски", "categoryId": 19},
        {"id": 13, "name": "Чесночный", "categoryId": 14},
        {"id": 14, "name": "Сладкий черри", "categoryId": 14},
        {"id": 15, "name": "Горчица", "categoryId": 14},
        {"id": 16, "name": "Чили - вода с перцем", "categoryId": 14},
        {"id": 17, "name": "Замес с омлетом и майонезом", "categoryId": 14},
        {"id": 18, "name": "Маринованные огурцы", "categoryId": 12},
        {"id": 19, "name": "Ананасы", "categoryId": 12},
        {
          "id": 20,
          "name": "Халапеньо, в неметаллическом контейнере",
          "categoryId": 12
        },
        {"id": 0, "name": "Картофель фри", "categoryId": 13},
        {"id": 21, "name": "Картофель фри для шаурмы", "categoryId": 20},
        {"id": 22, "name": "Омлет яичный", "categoryId": 20},
        {"id": 23, "name": "Шампиньоны фри", "categoryId": 20},
        {"id": 24, "name": "Филе цыпленка", "categoryId": 20},
        {"id": 25, "name": "Лук фри", "categoryId": 20},
        {"id": 26, "name": "Говядина фри", "categoryId": 20},
        {"id": 27, "name": "Фарш с соусом", "categoryId": 20},
        {"id": 28, "name": "Фарш куриный жареный", "categoryId": 20},
        {"id": 29, "name": "Чипсы пшеничные/острые", "categoryId": 20},
        {"id": 290, "name": "Чипсы острые", "categoryId": 20},
        {"id": 30, "name": "Бекон", "categoryId": 16},
        {"id": 31, "name": "Меланж яичный", "categoryId": 17},
        {"id": 32, "name": "Обычный", "categoryId": 1},
        {"id": 33, "name": "Сырный", "categoryId": 1},
        {"id": 34, "name": "Грибной", "categoryId": 1},
        {"id": 35, "name": "Кетчуп томатный EFKO FOOD", "categoryId": 1},
        {"id": 36, "name": "BBQ", "categoryId": 1},
        {"id": 37, "name": "Сладкий соус для курицы Агoy-D", "categoryId": 1},
        {"id": 248, "name": "Соус устричный", "categoryId": 27},
        {"id": 241, "name": "Соевый соус концентрат", "categoryId": 27},
        {"id": 242, "name": "Сырный", "categoryId": 27},
        {"id": 243, "name": "Сладкий соус для курицы Aroy-D", "categoryId": 27},
        {"id": 244, "name": "Соус для пиццы СООКМЕ", "categoryId": 27},
        {"id": 245, "name": "Сливки", "categoryId": 27},
        {"id": 246, "name": "Растительное масло", "categoryId": 28},
        {"id": 247, "name": "Соль", "categoryId": 28},
        {"id": 298, "name": "Caxap", "categoryId": 28},
        {"id": 249, "name": "Орегано", "categoryId": 28},
        {
          "id": 250,
          "name": "Приправа «Knorr» куриный бульон",
          "categoryId": 28
        },
        {"id": 251, "name": "Перец черный молотый", "categoryId": 28},
        {"id": 252, "name": "Лук жареный криспи", "categoryId": 28},
        {"id": 253, "name": "Лимонный концентрат", "categoryId": 28},
        {"id": 254, "name": "Яичный порошок", "categoryId": 28},
        {"id": 255, "name": "Дрожжи", "categoryId": 28},
        {"id": 256, "name": "Мука", "categoryId": 28},
        {"id": 38, "name": " Филе цыпленка", "categoryId": 10},
        {"id": 39, "name": "Крылья цыпленка", "categoryId": 10},
        {"id": 40, "name": "Говядина", "categoryId": 10},
        {"id": 41, "name": "Фарш из мяса птицы", "categoryId": 10},
        {"id": 42, "name": "Сардельки без оболочки", "categoryId": 11},
        {"id": 43, "name": "Растительное масло", "categoryId": 11},
        {"id": 44, "name": "Соль экстра", "categoryId": 22},
        {"id": 45, "name": "Фритюрное масло", "categoryId": 22},
        {"id": 46, "name": "Булочки для хот дога", "categoryId": 22},
        {"id": 47, "name": "Лаваш", "categoryId": 22},
        {"id": 48, "name": "Лепешка для грильяса", "categoryId": 22},
        {"id": 49, "name": "Яичный порошок", "categoryId": 22},
        {"id": 50, "name": "Картофель фри", "categoryId": 22},
        {"id": 51, "name": "Сервелат", "categoryId": 23},
        {"id": 510, "name": "Карбонад", "categoryId": 23},
        {"id": 52, "name": "Пепперони", "categoryId": 23},
        {"id": 53, "name": "Ветчина из мяса птицы", "categoryId": 23},
        {"id": 54, "name": "Фарш куриный жареный", "categoryId": 23},
        {"id": 55, "name": "Бекон", "categoryId": 23},
        {"id": 288, "name": "Филе цыпленка полуфабрикат", "categoryId": 26},
        {"id": 56, "name": "Пармезан", "categoryId": 24},
        {"id": 57, "name": " Дор-блю", "categoryId": 24},
        {"id": 58, "name": "Пицца сырный борт", "categoryId": 24},
        {"id": 578, "name": "Пармезан", "categoryId": 32},
        {"id": 579, "name": " Дор-блю", "categoryId": 32},
        {"id": 589, "name": "Пицца сырный борт", "categoryId": 32},
        {"id": 590, "name": "Моцарелла тертая", "categoryId": 32},
        {"id": 591, "name": "Сыр Голландский слайс", "categoryId": 32},
        {"id": 592, "name": "Очаковский", "categoryId": 32},
        {"id": 593, "name": "Сиртаки", "categoryId": 32},
        {"id": 59, "name": "Ананасы", "categoryId": 25},
        {"id": 60, "name": "Маринованные огурцы", "categoryId": 25},
        {
          "id": 61,
          "name": "Халапеньо, в неметаллическом контейнере",
          "categoryId": 25
        },
        {"id": 62, "name": "Белый", "categoryId": 35},
        {"id": 63, "name": "Красный для пиццы", "categoryId": 35},
        {"id": 64, "name": "Соевый соус полуфабрикат", "categoryId": 35},
        {"id": 65, "name": "Сливочный", "categoryId": 35},
        {"id": 66, "name": "Цезарь", "categoryId": 35},
        {"id": 67, "name": "BBQ", "categoryId": 35},
        {"id": 68, "name": "Шампиньоны", "categoryId": 36},
        {"id": 69, "name": "Томаты", "categoryId": 36},
        {"id": 70, "name": "Лук зеленый", "categoryId": 36},
        {"id": 71, "name": "Укроп", "categoryId": 36},
        {"id": 72, "name": "Лук красный", "categoryId": 36},
        {"id": 73, "name": "Айсберг", "categoryId": 36},
        {"id": 74, "name": "Лук белый маринованный", "categoryId": 37},
        {"id": 75, "name": "Тесто дрожжевое", "categoryId": 38},
        {"id": 76, "name": "Филе цыпленка", "categoryId": 39},
        {"id": 77, "name": "Масло чесночное", "categoryId": 39},
        {"id": 78, "name": "Фарш с соусом", "categoryId": 39},
        {"id": 79, "name": "Картофель фри для шаурмы", "categoryId": 39},
        {"id": 80, "name": "Яичный меланж", "categoryId": 60},
        {"id": 83, "name": "Сардельки без оболочки", "categoryId": 41},
        {"id": 84, "name": "Карбонад", "categoryId": 41},
        {"id": 85, "name": "Сервелат", "categoryId": 41},
        {"id": 86, "name": "Бекон", "categoryId": 41},
        {"id": 87, "name": "Моцарелла тертая", "categoryId": 42},
        {"id": 88, "name": "Сиртаки", "categoryId": 42},
        {"id": 89, "name": "Креметте", "categoryId": 42},
        {"id": 90, "name": "Пармезан", "categoryId": 42},
        {"id": 91, "name": " Форель", "categoryId": 43},
        {"id": 92, "name": "Креветки сырые", "categoryId": 43},
        {"id": 93, "name": "Снежный краб", "categoryId": 43},
        {"id": 94, "name": "Угорь", "categoryId": 43},
        {"id": 95, "name": "Икра Масаго оранжевая", "categoryId": 43},
        {"id": 96, "name": "Икра Масаго красная", "categoryId": 43},
        {"id": 97, "name": "Паста том ям", "categoryId": 44},
        {"id": 98, "name": "Паста чили тайская", "categoryId": 44},
        {"id": 99, "name": "Молоко кокосовое", "categoryId": 44},
        {"id": 100, "name": "Чили Mivimex", "categoryId": 44},
        {"id": 101, "name": " Соус рыбный", "categoryId": 44},
        {"id": 102, "name": "Соус сладкий для курицы Агoy-D", "categoryId": 44},
        {"id": 103, "name": "Майонез Печагин", "categoryId": 44},
        {"id": 104, "name": " Соус устричный", "categoryId": 44},
        {"id": 105, "name": "Унаги", "categoryId": 44},
        {"id": 106, "name": "Кетчуп томатный EFKO FOOD", "categoryId": 44},
        {"id": 107, "name": "Ким Чи", "categoryId": 44},
        {"id": 108, "name": "Соевый соус концентрат", "categoryId": 44},
        {"id": 109, "name": "Сливки", "categoryId": 44},
        {"id": 110, "name": "BBQ", "categoryId": 44},
        {"id": 111, "name": "Рис", "categoryId": 45},
        {"id": 112, "name": "Рисовое вино Мирин", "categoryId": 45},
        {"id": 113, "name": "Крахмал", "categoryId": 45},
        {"id": 114, "name": "Фритюрное масло", "categoryId": 45},
        {"id": 115, "name": "Оливковое масло", "categoryId": 45},
        {"id": 116, "name": "Растительное масло", "categoryId": 45},
        {"id": 117, "name": "Соль", "categoryId": 45},
        {"id": 118, "name": "Caxap", "categoryId": 45},
        {"id": 119, "name": "Имбирь маринованный", "categoryId": 45},
        {"id": 120, "name": "Сахарная пудра", "categoryId": 45},
        {"id": 121, "name": "Приправа Knorr куриный бульон", "categoryId": 45},
        {"id": 122, "name": "Кунжутное масло", "categoryId": 45},
        {"id": 123, "name": "BBQ", "categoryId": 45},
        {"id": 124, "name": "Стружка тунца", "categoryId": 45},
        {"id": 125, "name": "Водоросли нори", "categoryId": 45},
        {"id": 126, "name": "Панировочные сухари", "categoryId": 45},
        {"id": 127, "name": "Уксус рисовый Мицукан", "categoryId": 45},
        {"id": 128, "name": "Кунжут белый", "categoryId": 45},
        {"id": 129, "name": "Кунжут черный", "categoryId": 45},
        {"id": 130, "name": "Какао", "categoryId": 45},
        {"id": 131, "name": "Яичный порошок", "categoryId": 45},
        {"id": 132, "name": "Орегано", "categoryId": 45},
        {"id": 133, "name": "Лимонный концентрат", "categoryId": 45},
        {"id": 134, "name": "Лук жареный криспи", "categoryId": 45},
        {"id": 135, "name": "Ананасы", "categoryId": 46},
        {"id": 136, "name": "Маслины", "categoryId": 46},
        {"id": 137, "name": "Оливки", "categoryId": 46},
        {"id": 138, "name": "Маринованные огурцы", "categoryId": 46},
        {"id": 139, "name": "Яичная", "categoryId": 47},
        {"id": 140, "name": "Удон", "categoryId": 47},
        {"id": 141, "name": "Говядина", "categoryId": 48},
        {"id": 142, "name": "Филе цыпленка", "categoryId": 48},
        {"id": 143, "name": "Куриная грудка", "categoryId": 48},
        {"id": 144, "name": "Фасоль стручковая", "categoryId": 49},
        {"id": 145, "name": "Картофель фри", "categoryId": 50},
        {"id": 1450, "name": "Топпинг в ассортименте", "categoryId": 51},
        {"id": 146, "name": "Чизкейк в ассортименте", "categoryId": 51},
        {"id": 1445, "name": "Сырники", "categoryId": 51},
        {"id": 147, "name": "Лава", "categoryId": 52},
        {"id": 594, "name": "Терияки", "categoryId": 52},
        {"id": 148, "name": "Цезарь", "categoryId": 52},
        {"id": 149, "name": "Соевый соус полуфабрикат", "categoryId": 52},
        {"id": 150, "name": "Греческая заправка", "categoryId": 52},
        {"id": 151, "name": "Спайс", "categoryId": 52},
        {"id": 152, "name": "Мицукан заправка для риса", "categoryId": 52},
        {"id": 153, "name": "Васаби", "categoryId": 52},
        {"id": 154, "name": "Красный для пиццы", "categoryId": 52},
        {"id": 155, "name": "Соус базовый вок ", "categoryId": 52},
        {"id": 156, "name": "Соус сливочный вок", "categoryId": 52},
        {"id": 157, "name": "Соус устричный вок", "categoryId": 52},
        {"id": 158, "name": "BBQ", "categoryId": 52},
        {"id": 159, "name": "Кляр", "categoryId": 53},
        {"id": 160, "name": "Шампиньоны", "categoryId": 54},
        {"id": 161, "name": "Томаты", "categoryId": 54},
        {"id": 162, "name": "Лук белый", "categoryId": 54},
        {"id": 163, "name": "Лук красный", "categoryId": 54},
        {"id": 164, "name": "Лук белый маринованный", "categoryId": 54},
        {"id": 165, "name": "Айсберг", "categoryId": 54},
        {"id": 166, "name": "Апельсин", "categoryId": 54},
        {"id": 167, "name": "Банан", "categoryId": 54},
        {"id": 168, "name": "Груша", "categoryId": 54},
        {"id": 1680, "name": "Киби", "categoryId": 54},
        {"id": 169, "name": "Лимон", "categoryId": 54},
        {"id": 170, "name": "Лук зеленый", "categoryId": 54},
        {"id": 171, "name": "Морковь", "categoryId": 54},
        {"id": 172, "name": "Огурцы ", "categoryId": 54},
        {"id": 173, "name": "Перец чили", "categoryId": 54},
        {"id": 174, "name": "Болгарский перец", "categoryId": 54},
        {"id": 175, "name": "Укроп", "categoryId": 54},
        {"id": 176, "name": "Чеснок", "categoryId": 54},
        {"id": 177, "name": "Корень имбиря", "categoryId": 54},
        {"id": 178, "name": "Яйцо куриное(вареное)", "categoryId": 55},
        {"id": 1708, "name": "Яйцо куриное(вар очищенное)", "categoryId": 55},
        {"id": 1780, "name": "Яйцо куриное(мытое) ", "categoryId": 55},
        {"id": 179, "name": "Яичный меланж", "categoryId": 55},
        {"id": 180, "name": "С форелью", "categoryId": 56},
        {"id": 181, "name": "Цезарь", "categoryId": 56},
        {"id": 182, "name": "Сладкий сыр", "categoryId": 56},
        {"id": 183, "name": "Роскошь Бермудов", "categoryId": 56},
        {"id": 184, "name": "Краб+Спайс", "categoryId": 56},
        {
          "id": 185,
          "name": "Сырные шарики полуфабрикаты всех видов",
          "categoryId": 57
        },
        {"id": 186, "name": "Бульон рыбный", "categoryId": 58},
        {"id": 187, "name": "Бульон куриный", "categoryId": 58},
        {"id": 188, "name": "Булочки", "categoryId": 58},
        {"id": 189, "name": "Яичная лапша", "categoryId": 58},
        {"id": 190, "name": "Удон лапша", "categoryId": 58},
        {"id": 191, "name": "Блин сладкий", "categoryId": 58},
        {"id": 192, "name": "Блин яичный", "categoryId": 58},
        {"id": 193, "name": "Блин шоколадный", "categoryId": 58},
        {"id": 194, "name": "Рис для суши", "categoryId": 58},
        {"id": 1940, "name": "Рис для суши(из термоса)", "categoryId": 58},
        {"id": 195, "name": "Креветки вареные", "categoryId": 58},
        {"id": 196, "name": "Грибы Шиитаке", "categoryId": 58},
        {"id": 197, "name": "Куриная грудка жареная", "categoryId": 58},
        {"id": 198, "name": "Лосось терияки жареный", "categoryId": 58},
        {"id": 199, "name": "Сухари", "categoryId": 58},
        {"id": 200, "name": "Картофель фри для шаурмы", "categoryId": 58},
        {"id": 201, "name": "Томат Черри", "categoryId": 59},
        {"id": 202, "name": "Лук зеленый свежий", "categoryId": 59},
        {"id": 203, "name": "Лимон", "categoryId": 59},
        {"id": 204, "name": "Капуста белокочанная", "categoryId": 59},
        {"id": 205, "name": "Томат", "categoryId": 59},
        {"id": 206, "name": "Огурцы", "categoryId": 59},
        {"id": 207, "name": "Лук белый", "categoryId": 59},
        {"id": 208, "name": "Лук крымский", "categoryId": 59},
        {"id": 209, "name": "Перец сладкий", "categoryId": 59},
        {"id": 210, "name": "Шампиньоны", "categoryId": 59},
        {"id": 211, "name": "Айсберг", "categoryId": 59},
        {"id": 212, "name": "Банан", "categoryId": 59},
        {"id": 213, "name": "Укроп", "categoryId": 59},
        {"id": 214, "name": "Киви", "categoryId": 59},
        {"id": 215, "name": "Чеснок", "categoryId": 59},
        {"id": 216, "name": "Перец чили", "categoryId": 59},
        {"id": 217, "name": "Корень имбиря", "categoryId": 59},
        {"id": 218, "name": "Томаты", "categoryId": 60},
        {"id": 219, "name": "Томаты (хот-дог)", "categoryId": 60},
        {"id": 220, "name": "Огурцы", "categoryId": 60},
        {"id": 221, "name": "Томаты черри", "categoryId": 60},
        {"id": 222, "name": "Болгарский перец", "categoryId": 60},
        {"id": 223, "name": "Лук(белый)", "categoryId": 60},
        {"id": 224, "name": "Лук(репка)", "categoryId": 60},
        {"id": 225, "name": "Лук (красный)", "categoryId": 60},
        {"id": 226, "name": "Шампиньоны", "categoryId": 60},
        {"id": 227, "name": "Капуста", "categoryId": 60},
        {"id": 228, "name": "Лук зеленый", "categoryId": 60},
        {"id": 229, "name": "Огурец (марин.)", "categoryId": 60},
        {"id": 230, "name": "Морковь (кор.)", "categoryId": 60},
        {"id": 231, "name": "Лук репка марин.", "categoryId": 60},
        {"id": 232, "name": "Салат", "categoryId": 60},
        {"id": 233, "name": "Укроп", "categoryId": 60},
        {"id": 234, "name": "Горчица", "categoryId": 60},
        {"id": 235, "name": "Чили соус", "categoryId": 60},
        {"id": 236, "name": "Аройд", "categoryId": 60},
        {"id": 237, "name": "Красный соус", "categoryId": 60},
        {"id": 238, "name": "Соус обычный", "categoryId": 60},
        {"id": 239, "name": "Соус чесночный", "categoryId": 60},
        {"id": 240, "name": "Снежный краб", "categoryId": 29},
        {
          "id": 2410,
          "name": "Креветка сырая",
          "categoryId": 29
        } // ... Ajoutez d'autres données initiales ici
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
          "ouvert": 0,
          "categoryId": 10,
          "temperature": "-18°С",
          "subCategoryId": 41,
          "dureeDeConservation": "180 jours",
          "indicateur": 1
        },
        {
          "id": 2,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 38,
          "dureeDeConservation": "48 jours",
          "indicateur": 0
        },
        {
          "id": 3,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 39,
          "dureeDeConservation": "48 jours",
          "indicateur": 0
        },
        {
          "id": 4,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 40,
          "dureeDeConservation": "48 jours",
          "indicateur": 0
        },
        {
          "id": 5,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 41,
          "dureeDeConservation": "48 jours",
          "indicateur": 0
        },
        {
          "id": 6,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 32,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 7,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 33,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 8,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 34,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 9,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 35,
          "dureeDeConservation": "15 jours",
          "indicateur": 0
        },
        {
          "id": 10,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 36,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id": 11,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 37,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 12,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "до +20°С",
          "subCategoryId": 35,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 13,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "до +20°С",
          "subCategoryId": 36,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 14,
          "ouvert": 1,
          "categoryId": 11,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 42,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 15,
          "ouvert": 1,
          "categoryId": 11,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 43,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 16,
          "ouvert": 1,
          "categoryId": 12,
          "temperature": "до +20°С",
          "subCategoryId": 18,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 17,
          "ouvert": 1,
          "categoryId": 12,
          "temperature": "до +20°С",
          "subCategoryId": 19,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 18,
          "ouvert": 1,
          "categoryId": 12,
          "temperature": "до +20°С",
          "subCategoryId": 20,
          "dureeDeConservation": "21 jours",
          "indicateur": 0
        },
        {
          "id": 19,
          "ouvert": 0,
          "categoryId": 13,
          "temperature": "-18°С",
          "subCategoryId": 0,
          "dureeDeConservation": "7 jours",
          "indicateur": 1
        },
        {
          "id": 20,
          "ouvert": 1,
          "categoryId": 13,
          "temperature": "до +20°С",
          "subCategoryId": 0,
          "dureeDeConservation": "30 minutes",
          "indicateur": 0
        },
        {
          "id": 21,
          "ouvert": 1,
          "categoryId": 21,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 1,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 22,
          "ouvert": 1,
          "categoryId": 21,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 2,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 23,
          "ouvert": 1,
          "categoryId": 21,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 5,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 24,
          "ouvert": 1,
          "categoryId": 21,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 9,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 25,
          "ouvert": 1,
          "categoryId": 21,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 3,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 26,
          "ouvert": 1,
          "categoryId": 21,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 4,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 27,
          "ouvert": 1,
          "categoryId": 21,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 10,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 28,
          "ouvert": 1,
          "categoryId": 21,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 6,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 29,
          "ouvert": 1,
          "categoryId": 21,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 8,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 30,
          "ouvert": 1,
          "categoryId": 19,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 11,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 31,
          "ouvert": 1,
          "categoryId": 19,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 12,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 32,
          "ouvert": 1,
          "categoryId": 14,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 15,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 33,
          "ouvert": 1,
          "categoryId": 14,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 16,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 34,
          "ouvert": 1,
          "categoryId": 14,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 13,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 35,
          "ouvert": 1,
          "categoryId": 14,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 14,
          "dureeDeConservation": "15 jours",
          "indicateur": 0
        },
        {
          "id": 36,
          "ouvert": 1,
          "categoryId": 14,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 20,
          "dureeDeConservation": "6 heures",
          "indicateur": 0
        },
        {
          "id": 37,
          "ouvert": 1,
          "categoryId": 12,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 18,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 38,
          "ouvert": 1,
          "categoryId": 12,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 19,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 39,
          "ouvert": 1,
          "categoryId": 12,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 20,
          "dureeDeConservation": "21 jours",
          "indicateur": 0
        },
        {
          "id": 40,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 24,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 41,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 22,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 42,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 27,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 43,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 28,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 44,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "до +20°С",
          "subCategoryId": 21,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id": 44,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "до +20°С",
          "subCategoryId": 23,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id": 44,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "до +20°С",
          "subCategoryId": 24,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id": 44,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "до +20°С",
          "subCategoryId": 25,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id": 45,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "до +20°С",
          "subCategoryId": 27,
          "dureeDeConservation": "3 heures",
          "indicateur": 0
        },
        {
          "id": 46,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "до +20°С",
          "subCategoryId": [29, 290],
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        
        {
          "id": 46,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "до +20°С",
          "subCategoryId": 29,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 240,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "до +20°С",
          "subCategoryId": 290,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 48,
          "ouvert": 1,
          "categoryId": 16,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 30,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 49,
          "ouvert": 1,
          "categoryId": 17,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 31,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 50,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 51,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 51,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 510,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 52,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 52,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 53,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 53,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 54,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 55,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 55,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 56,
          "dureeDeConservation": "168 heures",
          "indicateur": 0
        },
        {
          "id": 56,
          "ouvert": 1,
          "categoryId": 24,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 57,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 57,
          "ouvert": 1,
          "categoryId": 24,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 58,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 58,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 592,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 59,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 593,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 60,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 589,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 61,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 590,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 62,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 591,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 63,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 579,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 64,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 578,
          "dureeDeConservation": "168 heures",
          "indicateur": 0
        },
        {
          "id": 65,
          "ouvert": 1,
          "categoryId": 25,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 59,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 66,
          "ouvert": 1,
          "categoryId": 25,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 61,
          "dureeDeConservation": "21 jours",
          "indicateur": 0
        },
        {
          "id": 67,
          "ouvert": 1,
          "categoryId": 25,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 60,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 68,
          "ouvert": 1,
          "categoryId": 27,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 244,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 69,
          "ouvert": 1,
          "categoryId": 27,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 245,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 70,
          "ouvert": 1,
          "categoryId": 27,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 243,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 71,
          "ouvert": 1,
          "categoryId": 27,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 242,
          "dureeDeConservation": "120 jours",
          "indicateur": 0
        },
        {
          "id": 72,
          "ouvert": 1,
          "categoryId": 27,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 241,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        {
          "id": 73,
          "ouvert": 1,
          "categoryId": 27,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 240,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 74,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "до +20°С",
          "subCategoryId": 256,
          "dureeDeConservation": "18 mois",
          "indicateur": 0
        },
        {
          "id": 75,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "до +20°С",
          "subCategoryId": 246,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        {
          "id": 75,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "до +20°С",
          "subCategoryId": 250,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        {
          "id": 76,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "до +20°С",
          "subCategoryId": 247,
          "dureeDeConservation": "2 ans",
          "indicateur": 0
        },
        {
          "id": 77,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "до +20°С",
          "subCategoryId": 248,
          "dureeDeConservation": "4 ans",
          "indicateur": 0
        },
        {
          "id": 78,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "до +20°С",
          "subCategoryId": 249,
          "dureeDeConservation": "36 mois",
          "indicateur": 0
        },
        {
          "id": 79,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "до +20°С",
          "subCategoryId": 251,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id": 80,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "до +20°С",
          "subCategoryId": 252,
          "dureeDeConservation": "14 mois",
          "indicateur": 0
        },
        {
          "id": 81,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "до +20°С",
          "subCategoryId": 253,
          "dureeDeConservation": "8 mois",
          "indicateur": 0
        },
        {
          "id": 82,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "до +20°С",
          "subCategoryId": 254,
          "dureeDeConservation": "6 mois",
          "indicateur": 0
        },
        {
          "id": 83,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 54,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 84,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 56,
          "dureeDeConservation": "168 heures",
          "indicateur": 0
        },
        {
          "id": 85,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 57,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 86,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 58,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 87,
          "ouvert": 1,
          "categoryId": 35,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 62,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 88,
          "ouvert": 1,
          "categoryId": 35,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 63,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 89,
          "ouvert": 1,
          "categoryId": 35,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 65,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 90,
          "ouvert": 1,
          "categoryId": 35,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 66,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 91,
          "ouvert": 1,
          "categoryId": 35,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 64,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 92,
          "ouvert": 1,
          "categoryId": 35,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 67,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id": 93,
          "ouvert": 1,
          "categoryId": 35,
          "temperature": "до +20°С",
          "subCategoryId": 67,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 94,
          "ouvert": 1,
          "categoryId": 36,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 68,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id": 95,
          "ouvert": 1,
          "categoryId": 36,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 69,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id": 96,
          "ouvert": 1,
          "categoryId": 36,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 70,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id": 97,
          "ouvert": 1,
          "categoryId": 36,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 71,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id": 98,
          "ouvert": 1,
          "categoryId": 36,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 73,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id": 99,
          "ouvert": 1,
          "categoryId": 36,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 72,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 100,
          "ouvert": 1,
          "categoryId": 37,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 74,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 101,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 78,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 102,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 78,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 103,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 76,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 104,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "до +20°С",
          "subCategoryId": 76,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id": 105,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "до +20°С",
          "subCategoryId": 77,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 106,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "до +20°С",
          "subCategoryId": 78,
          "dureeDeConservation": "3 heures",
          "indicateur": 0
        },
        {
          "id": 107,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "до +20°С",
          "subCategoryId": 79,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id": 108,
          "ouvert": 1,
          "categoryId": 60,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 80,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 110,
          "ouvert": 1,
          "categoryId": 29,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 240,
          "dureeDeConservation": "32 heures",
          "indicateur": 0
        },
        {
          "id": 111,
          "ouvert": 1,
          "categoryId": 29,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 241,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 112,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 83,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 113,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 86,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 114,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 84,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 115,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 85,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 116,
          "ouvert": 1,
          "categoryId": 42,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 90,
          "dureeDeConservation": "168 heures",
          "indicateur": 0
        },
        {
          "id": 117,
          "ouvert": 1,
          "categoryId": 42,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 87,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 118,
          "ouvert": 1,
          "categoryId": 42,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 89,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 119,
          "ouvert": 1,
          "categoryId": 42,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 88,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 120,
          "ouvert": 1,
          "categoryId": 43,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 95,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 121,
          "ouvert": 1,
          "categoryId": 43,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 96,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 122,
          "ouvert": 1,
          "categoryId": 43,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 94,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 123,
          "ouvert": 1,
          "categoryId": 43,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 93,
          "dureeDeConservation": "32 heures",
          "indicateur": 0
        },
        {
          "id": 124,
          "ouvert": 1,
          "categoryId": 43,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 92,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 125,
          "ouvert": 1,
          "categoryId": 43,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 91,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 126,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 97,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 127,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 98,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },{
          "id": 128,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 100,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },{
          "id": 129,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 102,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },{
          "id": 130,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 102,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },{
          "id": 131,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 104,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },{
          "id": 132,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId":  105,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 133,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId":  107,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },




        {
          "id": 134,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 99,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 135,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 109,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id":136,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 101, 
          "dureeDeConservation": "6 mois",
          "indicateur": 0
        },
        {
          "id":137,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId":  131,
          "dureeDeConservation": "6 mois",
          "indicateur": 0
        },


        {
          "id":138,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 103,
          "dureeDeConservation": "180 heures",
          "indicateur": 0
        },
        {
          "id":139,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 110,
          "dureeDeConservation": "180 heures",
          "indicateur": 0
        },

        {
          "id":140,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 106,
          "dureeDeConservation": "15 jours",
          "indicateur": 0
        },
        {
          "id":141,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 108,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        { "id":142,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "до +20°С",
          "subCategoryId": 110,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id":143,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "до +20°С",
          "subCategoryId": 106,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id":144,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 111,
          "dureeDeConservation": "18 mois",
          "indicateur": 0
        },
        {
          "id":145,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 120,
          "dureeDeConservation": "18 mois",
          "indicateur": 0
        },
        {
          "id":146,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 126,
          "dureeDeConservation": "18 mois",
          "indicateur": 0
        },


        {
          "id":147,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 113,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id":148,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 122,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id":149,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 125,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id":150,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 117,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id":151,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 127,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id":152,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 133,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },

        {
          "id":153,
          "ouvert": 0,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 114,
          "dureeDeConservation": "12 mois",
          "indicateur": 1
        },
        {
          "id":154,
          "ouvert": 0,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 116,
          "dureeDeConservation": "12 mois",
          "indicateur": 1
        },{
          "id":155,
          "ouvert": 0,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId":  121, 
          "dureeDeConservation": "12 mois",
          "indicateur": 1
        },{
          "id":156,
          "ouvert": 0,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 128,
          "dureeDeConservation": "12 mois",
          "indicateur": 1
        },{
          "id":157,
          "ouvert": 0,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId":  129, 
          "dureeDeConservation": "12 mois",
          "indicateur": 1
        },{
          "id":158,
          "ouvert": 0,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 130,
          "dureeDeConservation": "12 mois",
          "indicateur": 1
        },


        {
          "id":159,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 123,
          "dureeDeConservation": "6 mois",
          "indicateur": 0
        },
        {
          "id":160,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 131,
          "dureeDeConservation": "6 mois",
          "indicateur": 0
        },

        {
          "id":161,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 134,
          "dureeDeConservation": "14 mois",
          "indicateur": 0
        },

        {
          "id":162,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 118,
          "dureeDeConservation": "4 ans",
          "indicateur": 0
        },
        {
          "id":163,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 112,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        {
          "id":164,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 115,
          "dureeDeConservation": "365 jours",
          "indicateur": 0
        },
        {
          "id":165,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 124,
          "dureeDeConservation": "14 jours",
          "indicateur": 0
        },
        {
          "id":166,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 131,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id":167,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 135,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id":168,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 136,
          "dureeDeConservation": "168 heures",
          "indicateur": 0
        },
        {
          "id":169,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 137,
          "dureeDeConservation": "168 heures",
          "indicateur": 0
        },

        {
          "id":170,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 138,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id":171,
          "ouvert": 1,
          "categoryId": 47,
          "temperature": "до +20°С",
          "subCategoryId": 139,
          "dureeDeConservation": "36 mois",
          "indicateur": 0
        },
        {
          "id":172,
          "ouvert": 1,
          "categoryId": 47,
          "temperature": "до +20°С",
          "subCategoryId": 140,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id":173,
          "ouvert": 1,
          "categoryId": 48,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 141, 
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id":174,
          "ouvert": 1,
          "categoryId": 48,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 142,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id":175,
          "ouvert": 1,
          "categoryId": 48,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 143,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id":176,
          "ouvert": 1,
          "categoryId": 49,
          "temperature": "-18°С",
          "subCategoryId": 144,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id":177,
          "ouvert": 1,
          "categoryId": 50,
          "temperature": "-18°С",
          "subCategoryId": 145,
          "dureeDeConservation": "7 jours",
          "indicateur": 0
        },
        {
          "id":178,
          "ouvert": 1,
          "categoryId": 50,
          "temperature": "до +20°С",
          "subCategoryId": 145,
          "dureeDeConservation": "30 minutes",
          "indicateur": 0
        },
        {
          "id":179,
          "ouvert": 1,
          "categoryId": 51,
          "temperature": "до +20°С",
          "subCategoryId": 1450,
          "dureeDeConservation": "21 jours",
          "indicateur": 0
        },
        {
          "id":180,
          "ouvert": 1,
          "categoryId": 51,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 146,
          "dureeDeConservation": "10 jours",
          "indicateur": 0
        },
        {
          "id":181,
          "ouvert": 0,
          "categoryId": 50,
          "temperature": "-18°С",
          "subCategoryId": 1445,
          "dureeDeConservation": "180 jours",
          "indicateur": 1
        },
        {
          "id":182,
          "ouvert": 1,
          "categoryId": 52,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 147,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id":183,
          "ouvert": 1,
          "categoryId": 52,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 594, 
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id":184,
          "ouvert": 1,
          "categoryId": 52,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 148,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id":185,
          "ouvert": 1,
          "categoryId": 52,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 154, 
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id":186,
          "ouvert": 1,
          "categoryId": 52,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 156,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id":187,
          "ouvert": 1,
          "categoryId": 52,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 150,
          "dureeDeConservation": "10 jours",
          "indicateur": 0
        },
        {
          "id":188,
          "ouvert": 1,
          "categoryId": 52,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 149,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id":189,
          "ouvert": 1,
          "categoryId": 52,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 153,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },

        {
          "id":190,
          "ouvert": 1,
          "categoryId": 52,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 155,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id":191,
          "ouvert": 1,
          "categoryId": 52,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 157,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id":192,
          "ouvert": 1,
          "categoryId": 52,
          "temperature": "до +20°С",
          "subCategoryId": 158,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id":193,
          "ouvert": 1,
          "categoryId": 52,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 158,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id":194,
          "ouvert": 1,
          "categoryId": 53,
          "temperature":"от +2 до +6°С",
          "subCategoryId":159,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id":195,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 
            160,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id":196,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 
            161
          ,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id":197,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 
            165
          ,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },{
          "id":198,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 
            166
          ,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },{
          "id":199,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 
            167,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },{
          "id":200,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 
            168,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },{
          "id":201,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 
            169,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },{
          "id":202,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 
            170,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },{
          "id":203,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 
            172,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },{
          "id":204,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 
            174,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },{
          "id":205,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 
            175,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },{
          "id":206,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 
            1680,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id":207,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 162, 
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id":208,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 163, 
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id":209,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 171,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },


        {
          "id":210,
          "ouvert": 1,
          "categoryId": 53,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 164,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id":211,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 173,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id":212,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 176, 
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id":213,
          "ouvert": 1,
          "categoryId": 54,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 177,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        
        {
          "id":214,
          "ouvert": 1,
          "categoryId": 55,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 1780,
          "dureeDeConservation": "12 jours",
          "indicateur": 0
        },
        {
          "id":215,
          "ouvert": 1,
          "categoryId": 55,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 178,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id":216,
          "ouvert": 1,
          "categoryId": 55,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 1708,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id":217,
          "ouvert": 1,
          "categoryId": 55,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 179,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id":218,
          "ouvert": 1,
          "categoryId": 56,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 180,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id":219,
          "ouvert": 1,
          "categoryId": 56,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 181,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id":220,
          "ouvert": 1,
          "categoryId": 56,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 182,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id":221,
          "ouvert": 1,
          "categoryId": 56,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 183,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id":222,
          "ouvert": 1,
          "categoryId": 56,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 184,
          "dureeDeConservation": "32 heures",
          "indicateur": 0
        },
        {
          "id":223,
          "ouvert": 1,
          "categoryId": 57,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 185,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id":224,
          "ouvert": 1,
          "categoryId": 58,
          "temperature":"от +2 до +6°С",
          "subCategoryId":186, 
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id":225,
          "ouvert": 1,
          "categoryId": 58,
          "temperature":"от +2 до +6°С",
          "subCategoryId":187,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id":226,
          "ouvert": 1,
          "categoryId": 58,
          "temperature":"от +2 до +6°С",
          "subCategoryId": 188,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id":227,
          "ouvert": 1,
          "categoryId": 58,
          "temperature":"от +2 до +6°С",
          "subCategoryId": 189,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id":228,
          "ouvert": 1,
          "categoryId": 58,
          "temperature":"от +2 до +6°С",
          "subCategoryId":190, 
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id":229,
          "ouvert": 1,
          "categoryId": 58,
          "temperature":"от +2 до +6°С",
          "subCategoryId":196,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id":230,
          "ouvert": 1,
          "categoryId": 58,
          "temperature":"от +2 до +6°С",
          "subCategoryId":197,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },


        {
          "id":231,
          "ouvert": 1,
          "categoryId": 58,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 191, 
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id":232,
          "ouvert": 1,
          "categoryId": 58,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 192, 
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id":233,
          "ouvert": 1,
          "categoryId": 58,
          "temperature": "от +2 до +6°С",
          "subCategoryId":  193,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id":234,
          "ouvert": 1,
          "categoryId": 58,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 198,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },

        {
          "id":235,
          "ouvert": 1,
          "categoryId": 58,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 194,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id":236,
          "ouvert": 1,
          "categoryId": 56,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 195,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id":237,
          "ouvert": 1,
          "categoryId": 56,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 199,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id":238,
          "ouvert": 1,
          "categoryId": 58,
          "temperature": "до +20°С",
          "subCategoryId": 194,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id":239,
          "ouvert": 1,
          "categoryId": 58,
          "temperature": "до +20°С",
          "subCategoryId": 200,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        }
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

  static Future<List<Temperature>> getTemperaturesByOpen(int open) async {
    try {
      if (kDebugMode) {
        print('getTemperaturesByOpen - Ouvert: $open');
      }

      Database db = await _instance.database;

      if (open != null) {
        List<Map<String, dynamic>> maps = await db.query(
          'Temperatures',
          where: 'ouvert = ?',
          whereArgs: [open],
        );

        // Ajout d'une impression pour examiner les données brutes de la base de données
        if (kDebugMode) {
          print('Raw data from the database: $maps');
        }

        List<Temperature> temperatures = List.generate(maps.length, (i) {
          try {
            // Ajout d'une impression pour examiner la valeur de "ouvert"
            if (kDebugMode) {
              print('Value of "ouvert" from the database: ${maps[i]['ouvert']}');
            }

            return Temperature.fromJson(maps[i]);
          } catch (e) {
            // Ajout d'une impression pour afficher les erreurs pendant la conversion
            if (kDebugMode) {
              print('Error converting database record to Temperature: $e');
            }
            // Vous pouvez choisir de renvoyer un objet Temperature par défaut en cas d'erreur
            return Temperature(
              id: 0,
              ouvert: 0,
              categoryId: 0,
              temperature: '',
              subCategoryId: 0,
              dureeDeConservation: '',
              indicateur: 0,
            );
          }
        });

        return temperatures;
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving temperatures: $e');
      }
      return [];
    }
  }
  
  static Future<List<SubCategory>> getSubCategoriesByFilteredCategories(List<Categorie> filteredCategories) async {
      try {
        Database db = await _instance.database;

        // Récupérer les IDs des catégories filtrées
        List<int> categoryIds = filteredCategories.map((categorie) => categorie.id).toList();

        // Requête pour récupérer les sous-catégories en fonction des IDs des catégories filtrées
        List<Map<String, dynamic>> maps = await db.query(
          'SubCategories',
          where: 'categoryId IN (${categoryIds.join(",")})',
        );

        // Convertir les résultats en objets SubCategorie
        List<SubCategory> subCategories = List.generate(maps.length, (i) {
          return SubCategory.fromJson(maps[i]);
        });

        return subCategories;
      } catch (e) {
        if (kDebugMode) {
          print('Erreur lors de la récupération des sous-catégories : $e');
        }
        rethrow;
      }
    }

  static Future<List<Categorie>> getCategorieByIdCuisine(Cuisine cuisine) async {
    try {
      Database db = await _instance.database;

      // Ajout de l'impression de débogage
      if (kDebugMode) {
        print('getCategorieByIdCuisine - Cuisine ID: ${cuisine.id}');
      }

      // Récupérer les catégories pour une cuisine spécifique
      List<Map<String, dynamic>> maps = await db.query('Categories',
          where: 'cuisineId = ?', whereArgs: [cuisine.id]);

      // Convertir les résultats en objets Categorie
      List<Categorie> categories = List.generate(maps.length, (i) {
        return Categorie.fromMap(maps[i]);
      });

      return categories;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des catégories : $e');
      }
      rethrow;
    }
  } 

  static Future<List<Categorie>> getCategoryFilter(
    List<Temperature> temperatureList, List<Categorie> allCategories) async {
    try {
      // Ajout de l'impression de débogage
      if (kDebugMode) {
        print('getCategoryFilter - TemperatureList: $temperatureList, AllCategories: $allCategories');
      }

      // Filtrer les catégories en fonction des categoryIds des objets Temperature fournis
      List<Categorie> filteredCategories = allCategories.where((category) {
        for (var temperature in temperatureList) {
          if (category.id == temperature.categoryId) {
            return true;
          }
        }
        return false;
      }).toList();

      // Ajout d'une impression pour vérifier les résultats
      if (kDebugMode) {
        print('getCategoryFilter - Résultats: $filteredCategories');
      }

      return filteredCategories;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des catégories filtrées : $e');
      }
      rethrow;
    }
  }









}
