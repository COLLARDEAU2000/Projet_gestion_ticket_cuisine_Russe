// ignore_for_file: unnecessary_null_comparison, duplicate_ignore, unrelated_type_equality_checks
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
      String path = join(documentsDirectory.path, 'last_x.db');

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

  Future<void> initializeCuisines() async {
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
        {"id": 1, "name": "ОВОЩИ", "cuisineId": 1},
        {"id": 2, "name": "МЯСО", "cuisineId": 1},
        {"id": 3, "name": "ГАСТРОНОМИЯ", "cuisineId": 1},
        {"id": 4, "name": "БАКАЛЕЯ", "cuisineId": 1},
        {"id": 5, "name": "ЗАМОРОЗКА", "cuisineId": 1},
        {"id": 6, "name": "СОУСЫ И ЗАМЕСЫ", "cuisineId": 1},
        {"id": 7, "name": "МЯСНАЯ ГАСТРОНОМИЯ", "cuisineId": 1},
        {"id": 8, "name": "ЯИЧНЫЕ ПРОДУКТЫ", "cuisineId": 1},
        {"id": 9, "name": "ПОЛУФАБРИКАТЫ ОВОЩНЫЕ МАРИНОВАННЫЕ", "cuisineId": 1},
        {
          "id": 10,
          "name": "ПОЛУФАБРИКАТЫ ПОСЛЕ ТЕРМИЧЕСКОЙ ОБРАБОТКИ",
          "cuisineId": 1
        },
        {"id": 11, "name": "СОУСЫ", "cuisineId": 1},
        {"id": 13, "name": "МЯСНАЯ ГАСТРОНОМИЯ", "cuisineId": 2},
        {"id": 14, "name": "СЫРНАЯ ГАСТРОНОМИЯ", "cuisineId": 2},
        {"id": 15, "name": "КОНСЕРВАЦИ", "cuisineId": 2},
        {"id": 16, "name": "Соусы", "cuisineId": 2},
        {"id": 17, "name": "МЯСО", "cuisineId": 2},
        {"id": 18, "name": "БАКАЛЕЯ", "cuisineId": 2},
        {"id": 19, "name": "МОРЕПРОДУКТЫ", "cuisineId": 2},
        {"id": 20, "name": "МЯСНАЯ ГАСТРОНОМИЯ", "cuisineId": 2},
        {"id": 21, "name": "СЫРНАЯ ГАСТРОНОМИЯ", "cuisineId": 2},
        {"id": 22, "name": "СОУСЫ ПОЛУФАБРИКАТ", "cuisineId": 2},
        {"id": 23, "name": "ОВОЩИ", "cuisineId": 2},
        {
          "id": 24,
          "name": "ПОЛУФАБРИКАТЫ ОВОЩНЫЕ МАРИНОВАННЫЕ",
          "cuisineId": 2
        },
        {"id": 25, "name": "ТЕСТО ПОЛУФАБРИКАТ", "cuisineId": 2},
        {"id": 26, "name": "Яичные продукты", "cuisineId": 2},
        {
          "id": 27,
          "name": "ПОЛУФАБРИКАТЫ ПОСЛЕ ТЕРМИЧЕСКОЙ ОБРАБОТКИ",
          "cuisineId": 2
        },
        {"id": 28, "name": "МЯСНАЯ ГАСТРОНОМИЯ", "cuisineId": 3},
        {"id": 29, "name": "СЫР", "cuisineId": 3},
        {"id": 30, "name": "МОРЕПРОДУКТЫ", "cuisineId": 3},
        {"id": 31, "name": "СОУСЫ", "cuisineId": 3},
        {"id": 32, "name": "БАКАЛЕЯ", "cuisineId": 3},
        {"id": 33, "name": "КОНСЕРВАЦИЯ", "cuisineId": 3},
        {"id": 34, "name": "ЛАПША", "cuisineId": 3},
        {"id": 35, "name": "МЯСО", "cuisineId": 3},
        {"id": 36, "name": "ЗАМАРОЖЕННЫЕ ПОЛУФАБРИКАТ", "cuisineId": 3},
        {"id": 37, "name": "ЗАМОРОЗКА", "cuisineId": 3},
        {"id": 38, "name": "ДЕСЕРТЫ", "cuisineId": 3},
        {"id": 39, "name": "СОУСЫ ПОЛУФАБРИКАТЫ", "cuisineId": 3},
        {"id": 40, "name": "ТЕСТО", "cuisineId": 3},
        {"id": 41, "name": "ОВОЩИ и ФРУКТЫ", "cuisineId": 3},
        {"id": 42, "name": "ЯЙЦО", "cuisineId": 3},
        {"id": 43, "name": "ЗАМЕСЫ HA РОЛЛЫ", "cuisineId": 3},
        {"id": 44, "name": "ЗАМЕСЫ HA СЫРНЫЕ ШАРИКИ", "cuisineId": 3},
        {
          "id": 45,
          "name": "ПОЛУФАБРИКАТЫ ПОСЛЕ ТЕРМИЧЕСКОЙ ОБРАБОТКИ",
          "cuisineId": 3
        },
        {"id": 46, "name": "Овощи и Фрукты", "cuisineId": 4},
        {"id": 47, "name": "Продукты", "cuisineId": 4},
        {"id": 900, "name": "КОНСЕРВАЦИЯ", "cuisineId": 1},
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
  Future<void> initializeSubCategories() async {
    try {
      Database db = await database;

      // Données initiales des sous-catégories
      List<Map<String, dynamic>> initialSubCategoryData = [
        {"id": 1, "name": "Томаты", "categoryId": 1},
        {"id": 2, "name": "Огурцы", "categoryId": 1},
        {"id": 3, "name": "Лук белый", "categoryId": 1},
        {"id": 4, "name": "Лук красный", "categoryId": 1},
        {"id": 5, "name": " Шампиньоны", "categoryId": 1},
        {"id": 6, "name": "Чеснок очищенный", "categoryId": 1},
        {"id": 7, "name": "Капуста", "categoryId": 1},
        {"id": 8, "name": "Mорковь", "categoryId": 1},
        {"id": 9, "name": "Перец болгарский", "categoryId": 1},
        {"id": 10, "name": " Филе цыпленка", "categoryId": 2},
        {"id": 11, "name": "Крылья цыпленка", "categoryId": 2},
        {"id": 12, "name": "Говядина", "categoryId": 2},
        {"id": 13, "name": "Фарш из мяса птицы", "categoryId": 2},
        {"id": 14, "name": "Сардельки без оболочки", "categoryId": 3},
        {"id": 15, "name": "Сыр Голландский слайс", "categoryId": 3},
        {"id": 16, "name": "Соль экстра", "categoryId": 4},
        {"id": 17, "name": "Растительное масло", "categoryId": 4},
        {"id": 18, "name": "Фритюрное масло", "categoryId": 4},
        {"id": 19, "name": "Булочки для хот дога", "categoryId": 4},
        {"id": 20, "name": "Лаваш", "categoryId": 4},
        {"id": 21, "name": "Лепешка для грильяса", "categoryId": 4},
        {"id": 22, "name": "Яичный порошок", "categoryId": 4},
        {"id": 26, "name": "Картофель фри", "categoryId": 5},
        {"id": 27, "name": "Чесночный", "categoryId": 6},
        {"id": 28, "name": "Горчица", "categoryId": 6},
        {"id": 29, "name": "Сладкий черри", "categoryId": 6},
        {"id": 30, "name": "Чили - вода с перцем", "categoryId": 6},
        {"id": 31, "name": "Замес с омлетом и майонезом", "categoryId": 6},
        {"id": 32, "name": "Бекон", "categoryId": 7},
        {"id": 33, "name": "яичный Mеланж ", "categoryId": 8},
        {"id": 34, "name": "Лук белый маринованный", "categoryId": 9},
        {"id": 35, "name": "Морковь по-корейски", "categoryId": 9},
        {"id": 36, "name": "Картофель фри для шаурмы", "categoryId": 10},
        {"id": 37, "name": "Филе цыпленка", "categoryId": 10},
        {"id": 38, "name": "Шампиньоны фри", "categoryId": 10},
        {"id": 39, "name": "Омлет яичный", "categoryId": 10},
        {"id": 40, "name": "Лук фри", "categoryId": 10},
        {"id": 41, "name": "Говядина фри", "categoryId": 10},
        {"id": 42, "name": "Фарш с соусом", "categoryId": 10},
        {"id": 43, "name": "Фарш куриный жареный", "categoryId": 10},
        {"id": 44, "name": "Чипсы пшеничные/острые", "categoryId": 10},
        {"id": 45, "name": "Обычный", "categoryId": 11},
        {"id": 46, "name": "Сырный", "categoryId": 11},
        {"id": 47, "name": "Грибной", "categoryId": 11},
        {"id": 48, "name": "Кетчуп томатный EFKO FOOD", "categoryId": 11},
        {"id": 49, "name": "BBQ", "categoryId": 11},
        {"id": 50, "name": "Сладкий соус для курицы Агoy-D", "categoryId": 11},
        {"id": 51, "name": "Сервелат", "categoryId": 13},
        {"id": 52, "name": "Карбонад", "categoryId": 13},
        {"id": 53, "name": "Пепперони", "categoryId": 13},
        {"id": 54, "name": "Ветчина из мяса птицы", "categoryId": 13},
        {"id": 55, "name": "Бекон", "categoryId": 13},
        {"id": 56, "name": "Моцарелла тертая", "categoryId": 14},
        {"id": 57, "name": "Сыр Голландский слайс", "categoryId": 14},
        {"id": 58, "name": "Пармезан", "categoryId": 14},
        {"id": 59, "name": " Дор-блю", "categoryId": 14},
        {"id": 60, "name": "Очаковский", "categoryId": 14},
        {"id": 61, "name": "Пицца сырный борт", "categoryId": 14},
        {"id": 62, "name": "Сиртаки", "categoryId": 14},
        {"id": 63, "name": "Ананасы", "categoryId": 15},
        {
          "id": 64,
          "name": "Халапеньо, в неметаллическом контейнере",
          "categoryId": 15
        },
        {"id": 65, "name": "Маринованные огурцы", "categoryId": 15},
        {"id": 66, "name": "Сливки", "categoryId": 16},
        {"id": 67, "name": " Соус устричный", "categoryId": 16},
        {"id": 68, "name": "Соус сладкий для курицы Агoy-D", "categoryId": 16},
        {"id": 69, "name": "Соевый соус концентрат", "categoryId": 16},
        {"id": 70, "name": "Сырный", "categoryId": 16},
        {"id": 71, "name": "Соус для пиццы СООКМЕ", "categoryId": 16},
        {"id": 72, "name": "Филе цыпленка полуфабрикат", "categoryId": 17},
        {"id": 73, "name": "Мука", "categoryId": 18},
        {"id": 74, "name": "Дрожжи", "categoryId": 18},
        {"id": 75, "name": "Растительное масло", "categoryId": 18},
        {"id": 76, "name": "Соль", "categoryId": 18},
        {"id": 77, "name": "Caxap", "categoryId": 18},
        {"id": 78, "name": "Орегано", "categoryId": 18},
        {"id": 79, "name": "Приправа «Knorr» куриный бульон", "categoryId": 18},
        {"id": 80, "name": "Перец черный молотый", "categoryId": 18},
        {"id": 81, "name": "Лук жареный криспи", "categoryId": 18},
        {"id": 82, "name": "Лимонный концентрат", "categoryId": 18},
        {"id": 83, "name": "Яичный порошок", "categoryId": 18},
        {"id": 84, "name": "Снежный краб", "categoryId": 19},
        {"id": 85, "name": "Креветка сырая", "categoryId": 19},
        {"id": 86, "name": "Сервелат", "categoryId": 20},
        {"id": 87, "name": "Карбонад", "categoryId": 20},
        {"id": 88, "name": "Пеперони", "categoryId": 20},
        {"id": 89, "name": "Ветчина из мяса птицы", "categoryId": 20},
        {"id": 90, "name": "Фарш куриный жареный", "categoryId": 20},
        {"id": 91, "name": "Бекон", "categoryId": 20},
        {"id": 92, "name": "Пармезан", "categoryId": 21},
        {"id": 93, "name": " Дор-блю", "categoryId": 21},
        {"id": 94, "name": "Пицца сырный борт", "categoryId": 21},
        {"id": 95, "name": "Белый", "categoryId": 22},
        {"id": 96, "name": "Красный для пиццы", "categoryId": 22},
        {"id": 97, "name": "Соевый соус полуфабрикат", "categoryId": 22},
        {"id": 98, "name": "Сливочный", "categoryId": 22},
        {"id": 99, "name": "Цезарь", "categoryId": 22},
        {"id": 100, "name": "BBQ", "categoryId": 22},
        {"id": 101, "name": "Шампиньоны", "categoryId": 23},
        {"id": 102, "name": "Томаты", "categoryId": 23},
        {"id": 103, "name": "Лук белый", "categoryId": 23},
        {"id": 104, "name": "Лук красный", "categoryId": 23},
        {"id": 105, "name": "Лук белый маринованный", "categoryId": 23},
        {"id": 106, "name": "Айсберг", "categoryId": 23},
        {"id": 107, "name": "Лук белый маринованный", "categoryId": 24},
        {"id": 108, "name": "Тесто дрожжевое", "categoryId": 25},
        {"id": 109, "name": "Яичный меланж", "categoryId": 26},
        {"id": 109, "name": "Филе цыпленка", "categoryId": 27},
        {"id": 110, "name": "Масло чесночное", "categoryId": 27},
        {"id": 111, "name": "Фарш с соусом", "categoryId": 27},
        {"id": 112, "name": "Картофель фри для шаурмы", "categoryId": 27},
        {"id": 113, "name": "Сардельки без оболочки", "categoryId": 28},
        {"id": 114, "name": "Карбонад", "categoryId": 28},
        {"id": 115, "name": "Сервелат", "categoryId": 28},
        {"id": 116, "name": "Бекон", "categoryId": 28},
        {"id": 117, "name": "Моцарелла тертая", "categoryId": 29},
        {"id": 118, "name": "Креметте", "categoryId": 29},
        {"id": 119, "name": "Пармезан", "categoryId": 29},
        {"id": 120, "name": "Сиртаки", "categoryId": 29},
        {"id": 121, "name": " Форель", "categoryId": 30},
        {"id": 122, "name": "Креветки сырые", "categoryId": 30},
        {"id": 123, "name": "Снежный краб", "categoryId": 30},
        {"id": 124, "name": "Угорь", "categoryId": 30},
        {"id": 125, "name": "Икра Масаго оранжевая", "categoryId": 30},
        {"id": 126, "name": "Икра Масаго красная", "categoryId": 30},
        {"id": 127, "name": "Чили Mivimex", "categoryId": 31},
        {"id": 128, "name": "Паста том ям", "categoryId": 31},
        {"id": 129, "name": "Паста чили тайская", "categoryId": 31},
        {"id": 130, "name": "Молоко кокосовое", "categoryId": 31},
        {"id": 131, "name": " Соус рыбный", "categoryId": 31},
        {
          "id": 132,
          "name": " Соус сладкий для курицы Aroy-D",
          "categoryId": 31
        },
        {"id": 133, "name": "Майонез Печагин", "categoryId": 31},
        {"id": 135, "name": "Унаги", "categoryId": 31},
        {"id": 136, "name": "Кетчуп томатный EFKO FOOD", "categoryId": 31},
        {"id": 137, "name": "Ким Чи", "categoryId": 31},
        {"id": 138, "name": "Соевый соус концентрат", "categoryId": 31},
        {"id": 139, "name": "Сливки", "categoryId": 31},
        {"id": 140, "name": "BBQ", "categoryId": 31},
        {"id": 141, "name": "Рис", "categoryId": 32},
        {"id": 142, "name": "Рисовое вино Мирин", "categoryId": 32},
        {"id": 143, "name": "Крахмал", "categoryId": 32},
        {"id": 144, "name": "Фритюрное масло", "categoryId": 32},
        {"id": 145, "name": "Оливковое масло", "categoryId": 32},
        {"id": 146, "name": "Растительное масло", "categoryId": 32},
        {"id": 147, "name": "Соль", "categoryId": 32},
        {"id": 148, "name": "Caxap", "categoryId": 32},
        {"id": 149, "name": "Имбирь маринованный", "categoryId": 32},
        {"id": 150, "name": "Сахарная пудра", "categoryId": 32},
        {"id": 151, "name": "Приправа Knorr куриный бульон", "categoryId": 32},
        {"id": 152, "name": "Кунжутное масло", "categoryId": 32},
        {"id": 153, "name": "BBQ", "categoryId": 32},
        {"id": 154, "name": "Водоросли нори", "categoryId": 32},
        {"id": 155, "name": "Ананасы", "categoryId": 33},
        {"id": 156, "name": "Маслины", "categoryId": 33},
        {"id": 157, "name": "Оливки", "categoryId": 33},
        {"id": 158, "name": "Маринованные огурцы", "categoryId": 33},
        {"id": 159, "name": "Яичная", "categoryId": 34},
        {"id": 160, "name": "Удон", "categoryId": 34},
        {"id": 161, "name": "Говядина", "categoryId": 35},
        {"id": 162, "name": "Филе цыпленка", "categoryId": 35},
        {"id": 163, "name": "Куриная грудка", "categoryId": 35},
        {"id": 164, "name": "Фасоль стручковая", "categoryId": 36},
        {"id": 165, "name": "Картофель фри", "categoryId": 37},
        {"id": 166, "name": "Топпинг в ассортименте", "categoryId": 38},
        {"id": 167, "name": "Чизкейк в ассортименте", "categoryId": 38},
        {"id": 168, "name": "Сырники", "categoryId": 38},
        {"id": 169, "name": "Лава", "categoryId": 39},
        {"id": 170, "name": "Цезарь", "categoryId": 39},
        {"id": 171, "name": "Соевый соус полуфабрикат", "categoryId": 39},
        {"id": 172, "name": "Греческая заправка", "categoryId": 39},
        {"id": 173, "name": "Спайс", "categoryId": 39},
        {"id": 174, "name": "Терияки", "categoryId": 39},
        {"id": 175, "name": "Мицукан заправка для риса", "categoryId": 39},
        {"id": 176, "name": "Васаби", "categoryId": 39},
        {"id": 177, "name": "Красный для пиццы", "categoryId": 39},
        {"id": 178, "name": "Соус базовый вок ", "categoryId": 39},
        {"id": 179, "name": "соус сливочный вок", "categoryId": 39},
        {"id": 180, "name": "Соус устричный вок", "categoryId": 39},
        {"id": 181, "name": "BBQ", "categoryId": 39},
        {"id": 201, "name": "Кляр", "categoryId": 40},
        {"id": 183, "name": "Шампиньоны", "categoryId": 41},
        {"id": 188, "name": "Апельсин", "categoryId": 41},
        {"id": 189, "name": "Банан", "categoryId": 41},
        {"id": 190, "name": "Груша", "categoryId": 41},
        {"id": 191, "name": "Киби", "categoryId": 41},
        {"id": 192, "name": "Лимон", "categoryId": 41},
        {"id": 193, "name": "Лук зеленый", "categoryId": 41},
        {"id": 194, "name": "Морковь", "categoryId": 41},
        {"id": 195, "name": "Огурцы ", "categoryId": 41},
        {"id": 196, "name": "Перец чили", "categoryId": 41},
        {"id": 197, "name": "Болгарский перец", "categoryId": 41},
        {"id": 198, "name": "Укроп", "categoryId": 41},
        {"id": 199, "name": "Чеснок", "categoryId": 41},
        {"id": 200, "name": "Корень имбиря", "categoryId": 41},
        {"id": 186, "name": "Лук белый маринованный", "categoryId": 41},
        {"id": 187, "name": "Айсберг", "categoryId": 41},
        {"id": 202, "name": "Яйцо куриное(вареное)", "categoryId": 42},
        {"id": 203, "name": "Яйцо куриное(вар очищенное)", "categoryId": 42},
        {"id": 204, "name": "Яйцо куриное(мытое) ", "categoryId": 42},
        {"id": 205, "name": "Яичный меланж", "categoryId": 42},
        {"id": 206, "name": "С форелью", "categoryId": 43},
        {"id": 207, "name": "Цезарь", "categoryId": 43},
        {"id": 208, "name": "Сладкий сыр", "categoryId": 43},
        {"id": 209, "name": "Роскошь Бермудов", "categoryId": 43},
        {"id": 210, "name": "Краб+Спайс", "categoryId": 43},
        {
          "id": 211,
          "name": "Сырные шарики полуфабрикаты всех видов",
          "categoryId": 44
        },
        {"id": 212, "name": "Бульон куриный", "categoryId": 45},
        {"id": 213, "name": "Бульон рыбный", "categoryId": 45},
        {"id": 214, "name": "Булочки", "categoryId": 45},
        {"id": 215, "name": "Яичная лапша", "categoryId": 45},
        {"id": 216, "name": "Удон лапша", "categoryId": 45},
        {"id": 217, "name": "Блин сладкий", "categoryId": 45},
        {"id": 218, "name": "Блин яичный", "categoryId": 45},
        {"id": 219, "name": "Блин шоколадный", "categoryId": 45},
        {"id": 220, "name": "Рис для суши", "categoryId": 45},
        {"id": 221, "name": "Рис для суши(из термоса)", "categoryId": 45},
        {"id": 222, "name": "Креветки вареные", "categoryId": 45},
        {"id": 223, "name": "Грибы Шиитаке", "categoryId": 45},
        {"id": 224, "name": "Куриная грудка жареная", "categoryId": 45},
        {"id": 225, "name": "Лосось терияки жареный", "categoryId": 45},
        {"id": 226, "name": "Сухари", "categoryId": 45},
        {"id": 227, "name": "Картофель фри для шаурмы", "categoryId": 45},
        {"id": 228, "name": "Томат Черри", "categoryId": 46},
        {"id": 229, "name": "Лук зеленый свежий", "categoryId": 46},
        {"id": 230, "name": "Лимон", "categoryId": 46},
        {"id": 231, "name": "Капуста белокочанная", "categoryId": 46},
        {"id": 232, "name": "Томат", "categoryId": 46},
        {"id": 233, "name": "Огурцы", "categoryId": 46},
        {"id": 234, "name": "Лук белый", "categoryId": 46},
        {"id": 235, "name": "Лук крымский", "categoryId": 46},
        {"id": 236, "name": "Морковь", "categoryId": 46},
        {"id": 237, "name": "Апельсин", "categoryId": 46},
        {"id": 238, "name": "Перец сладкий", "categoryId": 46},
        {"id": 239, "name": "Шампиньоны", "categoryId": 46},
        {"id": 240, "name": "Айсберг", "categoryId": 46},
        {"id": 241, "name": "Банан", "categoryId": 46},
        {"id": 242, "name": "Груша", "categoryId": 46},
        {"id": 243, "name": "Укроп", "categoryId": 46},
        {"id": 244, "name": "Киви", "categoryId": 46},
        {"id": 245, "name": "Чеснок", "categoryId": 46},
        {"id": 246, "name": "Перец чили", "categoryId": 46},
        {"id": 247, "name": "Корень имбиря", "categoryId": 46},
        {"id": 248, "name": "Томаты", "categoryId": 47},
        {"id": 249, "name": "Томаты (хот-дог)", "categoryId": 47},
        {"id": 250, "name": "Огурцы", "categoryId": 47},
        {"id": 251, "name": "Томаты черри", "categoryId": 47},
        {"id": 252, "name": "Болгарский перец", "categoryId": 47},
        {"id": 253, "name": "Лук(белый)", "categoryId": 47},
        {"id": 254, "name": "Лук(репка)", "categoryId": 47},
        {"id": 255, "name": "Лук (красный)", "categoryId": 47},
        {"id": 256, "name": "Шампиньоны", "categoryId": 47},
        {"id": 257, "name": "Капуста", "categoryId": 47},
        {"id": 258, "name": "Лук зеленый", "categoryId": 47},
        {"id": 259, "name": "Огурец (марин.)", "categoryId": 47},
        {"id": 260, "name": "Морковь (кор.)", "categoryId": 47},
        {"id": 261, "name": "Лук репка марин.", "categoryId": 47},
        {"id": 262, "name": "Салат", "categoryId": 47},
        {"id": 263, "name": "Укроп", "categoryId": 47},
        {"id": 264, "name": "Горчица", "categoryId": 47},
        {"id": 265, "name": "Чили соус", "categoryId": 47},
        {"id": 266, "name": "Аройд", "categoryId": 47},
        {"id": 267, "name": "Красный соус", "categoryId": 47},
        {"id": 268, "name": "Соус обычный", "categoryId": 47},
        {"id": 269, "name": "Соус чесночный", "categoryId": 47},
        {"id": 23, "name": "Маринованные огурцы", "categoryId": 900},
        {"id": 24, "name": "Ананасы", "categoryId": 900},
        {
          "id": 25,
          "name": "Халапеньо, в неметаллическом контейнере",
          "categoryId": 900
        },
        {"id": 444, "name": "Тесто", "categoryId": 25}
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

  static Future<List<SubCategory>> getSubCategoriesByIds(
      List<int> subCategoryIds) async {
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
        print(
            'Erreur lors de la récupération des sous-catégories par IDs : $e');
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
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 1,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 2,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 2,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 3,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 3,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 4,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 4,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 5,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 5,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 6,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 6,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 7,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 7,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 8,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 8,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 9,
          "ouvert": 1,
          "categoryId": 1,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 9,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 10,
          "ouvert": 1,
          "categoryId": 2,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 10,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 11,
          "ouvert": 1,
          "categoryId": 2,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 11,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 12,
          "ouvert": 1,
          "categoryId": 2,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 12,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 13,
          "ouvert": 1,
          "categoryId": 2,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 13,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 14,
          "ouvert": 0,
          "categoryId": 2,
          "temperature": "-18°С",
          "subCategoryId": 13,
          "dureeDeConservation": "180 jours",
          "indicateur": 1
        },
        {
          "id": 15,
          "ouvert": 1,
          "categoryId": 3,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 14,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 16,
          "ouvert": 1,
          "categoryId": 3,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 15,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 17,
          "ouvert": 1,
          "categoryId": 4,
          "temperature": "до +20°С",
          "subCategoryId": 16,
          "dureeDeConservation": "2 annees",
          "indicateur": 0
        },
        {
          "id": 18,
          "ouvert": 1,
          "categoryId": 4,
          "temperature": "до +20°С",
          "subCategoryId": 17,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        {
          "id": 19,
          "ouvert": 1,
          "categoryId": 4,
          "temperature": "до +20°С",
          "subCategoryId": 18,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        {
          "id": 20,
          "ouvert": 1,
          "categoryId": 4,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 19,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 21,
          "ouvert": 1,
          "categoryId": 4,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 20,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 22,
          "ouvert": 1,
          "categoryId": 4,
          "temperature": "до +20°С",
          "subCategoryId": 20,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 23,
          "ouvert": 1,
          "categoryId": 4,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 21,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 24,
          "ouvert": 1,
          "categoryId": 4,
          "temperature": "до +20°С",
          "subCategoryId": 21,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 25,
          "ouvert": 1,
          "categoryId": 4,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 22,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id": 26,
          "ouvert": 1,
          "categoryId": 4,
          "temperature": "до +20°С",
          "subCategoryId": 22,
          "dureeDeConservation": "6 mois",
          "indicateur": 0
        },
        {
          "id": 27,
          "ouvert": 1,
          "categoryId": 4,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 22,
          "dureeDeConservation": "15 heures",
          "indicateur": 0
        },
        {
          "id": 31,
          "ouvert": 0,
          "categoryId": 5,
          "temperature": "-18°С",
          "subCategoryId": 26,
          "dureeDeConservation": "7 jours",
          "indicateur": 1
        },
        {
          "id": 32,
          "ouvert": 1,
          "categoryId": 5,
          "temperature": "до +20°С",
          "subCategoryId": 26,
          "dureeDeConservation": "30 minutes",
          "indicateur": 0
        },
        {
          "id": 33,
          "ouvert": 1,
          "categoryId": 6,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 27,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 34,
          "ouvert": 1,
          "categoryId": 6,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 28,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 35,
          "ouvert": 1,
          "categoryId": 6,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 29,
          "dureeDeConservation": "15 jours",
          "indicateur": 0
        },
        {
          "id": 36,
          "ouvert": 1,
          "categoryId": 6,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 30,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 37,
          "ouvert": 1,
          "categoryId": 6,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 31,
          "dureeDeConservation": "6 heures",
          "indicateur": 0
        },
        {
          "id": 38,
          "ouvert": 1,
          "categoryId": 7,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 32,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 39,
          "ouvert": 1,
          "categoryId": 8,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 33,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 40,
          "ouvert": 1,
          "categoryId": 9,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 34,
          "dureeDeConservation": " 36 heures",
          "indicateur": 0
        },
        {
          "id": 41,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 35,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 42,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 36,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 43,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "до +20°С",
          "subCategoryId": 36,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id": 44,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 37,
          "dureeDeConservation": "24 heures ",
          "indicateur": 0
        },
        {
          "id": 45,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "до +20°С",
          "subCategoryId": 37,
          "dureeDeConservation": "4 heures ",
          "indicateur": 0
        },
        {
          "id": 46,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "до +20°С",
          "subCategoryId": 38,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id": 47,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 39,
          "dureeDeConservation": "18 heures ",
          "indicateur": 0
        },
        {
          "id": 48,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "до +20°С",
          "subCategoryId": 40,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id": 49,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "до +20°С",
          "subCategoryId": 41,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id": 50,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "до +20°С",
          "subCategoryId": 42,
          "dureeDeConservation": "3 heures",
          "indicateur": 0
        },
        {
          "id": 51,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 42,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 52,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 43,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 53,
          "ouvert": 1,
          "categoryId": 10,
          "temperature": "до +20°С",
          "subCategoryId": 44,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 54,
          "ouvert": 1,
          "categoryId": 11,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 45,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 55,
          "ouvert": 1,
          "categoryId": 11,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 46,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 56,
          "ouvert": 1,
          "categoryId": 11,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 47,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 57,
          "ouvert": 1,
          "categoryId": 11,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 48,
          "dureeDeConservation": "15 jours",
          "indicateur": 0
        },
        {
          "id": 58,
          "ouvert": 1,
          "categoryId": 11,
          "temperature": "до +20°С",
          "subCategoryId": 48,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 59,
          "ouvert": 1,
          "categoryId": 11,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 49,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id": 60,
          "ouvert": 1,
          "categoryId": 11,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 49,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 61,
          "ouvert": 1,
          "categoryId": 11,
          "temperature": "до +20°С",
          "subCategoryId": 50,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 56,
          "ouvert": 1,
          "categoryId": 13,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 51,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 57,
          "ouvert": 1,
          "categoryId": 13,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 52,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 58,
          "ouvert": 1,
          "categoryId": 13,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 53,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 59,
          "ouvert": 1,
          "categoryId": 13,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 54,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 60,
          "ouvert": 1,
          "categoryId": 13,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 55,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 61,
          "ouvert": 1,
          "categoryId": 14,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 56,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 62,
          "ouvert": 1,
          "categoryId": 14,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 57,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 63,
          "ouvert": 1,
          "categoryId": 14,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 58,
          "dureeDeConservation": "168 heures",
          "indicateur": 0
        },
        {
          "id": 64,
          "ouvert": 1,
          "categoryId": 14,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 59,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 65,
          "ouvert": 1,
          "categoryId": 13,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 60,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 66,
          "ouvert": 1,
          "categoryId": 14,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 61,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 67,
          "ouvert": 1,
          "categoryId": 14,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 62,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 68,
          "ouvert": 1,
          "categoryId": 14,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 61,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 69,
          "ouvert": 1,
          "categoryId": 14,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 62,
          "dureeDeConservation": "168 heures",
          "indicateur": 0
        },
        {
          "id": 70,
          "ouvert": 1,
          "categoryId": 15,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 63,
          "dureeDeConservation": "48 heures ",
          "indicateur": 0
        },
        {
          "id": 71,
          "ouvert": 1,
          "categoryId": 15,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 64,
          "dureeDeConservation": "21 jours",
          "indicateur": 0
        },
        {
          "id": 72,
          "ouvert": 1,
          "categoryId": 15,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 65,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 73,
          "ouvert": 1,
          "categoryId": 16,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 66,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 74,
          "ouvert": 1,
          "categoryId": 16,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 67,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 75,
          "ouvert": 1,
          "categoryId": 16,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 68,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 76,
          "ouvert": 1,
          "categoryId": 16,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 69,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        {
          "id": 77,
          "ouvert": 1,
          "categoryId": 16,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 70,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 78,
          "ouvert": 1,
          "categoryId": 16,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 71,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 79,
          "ouvert": 1,
          "categoryId": 17,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 72,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 80,
          "ouvert": 1,
          "categoryId": 18,
          "temperature": "до +20°С",
          "subCategoryId": 73,
          "dureeDeConservation": "18 mois",
          "indicateur": 0
        },
        {
          "id": 81,
          "ouvert": 1,
          "categoryId": 18,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 74,
          "dureeDeConservation": "168 heures",
          "indicateur": 0
        },
        {
          "id": 82,
          "ouvert": 1,
          "categoryId": 18,
          "temperature": "до +20°С",
          "subCategoryId": 75,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        {
          "id": 83,
          "ouvert": 1,
          "categoryId": 18,
          "temperature": "до +20°С",
          "subCategoryId": 76,
          "dureeDeConservation": "2 annees",
          "indicateur": 0
        },
        {
          "id": 84,
          "ouvert": 1,
          "categoryId": 18,
          "temperature": "до +20°С",
          "subCategoryId": 77,
          "dureeDeConservation": "4 annees",
          "indicateur": 0
        },
        {
          "id": 85,
          "ouvert": 1,
          "categoryId": 18,
          "temperature": "до +20°С",
          "subCategoryId": 78,
          "dureeDeConservation": "36 mois",
          "indicateur": 0
        },
        {
          "id": 86,
          "ouvert": 1,
          "categoryId": 18,
          "temperature": "до +20°С",
          "subCategoryId": 79,
          "dureeDeConservation": "2 ans",
          "indicateur": 0
        },
        {
          "id": 87,
          "ouvert": 1,
          "categoryId": 18,
          "temperature": "до +20°С",
          "subCategoryId": 80,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id": 88,
          "ouvert": 1,
          "categoryId": 18,
          "temperature": "до +20°С",
          "subCategoryId": 81,
          "dureeDeConservation": "14 mois",
          "indicateur": 0
        },
        {
          "id": 89,
          "ouvert": 1,
          "categoryId": 18,
          "temperature": "до +20°С",
          "subCategoryId": 82,
          "dureeDeConservation": "8 mois",
          "indicateur": 0
        },
        {
          "id": 90,
          "ouvert": 1,
          "categoryId": 18,
          "temperature": "до +20°С",
          "subCategoryId": 83,
          "dureeDeConservation": "6 mois",
          "indicateur": 0
        },
        {
          "id": 91,
          "ouvert": 1,
          "categoryId": 19,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 84,
          "dureeDeConservation": "32 heures",
          "indicateur": 0
        },
        {
          "id": 92,
          "ouvert": 1,
          "categoryId": 19,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 85,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 93,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 86,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 94,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 87,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 95,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 88,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 96,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 89,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 97,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 90,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 98,
          "ouvert": 1,
          "categoryId": 20,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 91,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 99,
          "ouvert": 1,
          "categoryId": 21,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 92,
          "dureeDeConservation": "168 heures",
          "indicateur": 0
        },
        {
          "id": 100,
          "ouvert": 1,
          "categoryId": 21,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 93,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 101,
          "ouvert": 1,
          "categoryId": 21,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 94,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 102,
          "ouvert": 1,
          "categoryId": 22,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 95,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 103,
          "ouvert": 1,
          "categoryId": 22,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 96,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 104,
          "ouvert": 1,
          "categoryId": 22,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 97,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 105,
          "ouvert": 1,
          "categoryId": 22,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 98,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 106,
          "ouvert": 1,
          "categoryId": 22,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 99,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 107,
          "ouvert": 1,
          "categoryId": 22,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 100,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id": 108,
          "ouvert": 1,
          "categoryId": 22,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 100,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 109,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 101,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 110,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 102,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 111,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 103,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 112,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 104,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 113,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 105,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 114,
          "ouvert": 1,
          "categoryId": 23,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 106,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 115,
          "ouvert": 1,
          "categoryId": 24,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 107,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 116,
          "ouvert": 1,
          "categoryId": 25,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 108,
          "dureeDeConservation": "24 heures ",
          "indicateur": 0
        },
        {
          "id": 117,
          "ouvert": 1,
          "categoryId": 26,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 109,
          "dureeDeConservation": "24 heures ",
          "indicateur": 0
        },
        {
          "id": 118,
          "ouvert": 1,
          "categoryId": 27,
          "temperature": "до +20°С",
          "subCategoryId": 109,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id": 119,
          "ouvert": 1,
          "categoryId": 27,
          "temperature": "до +20°С",
          "subCategoryId": 110,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 120,
          "ouvert": 1,
          "categoryId": 27,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 111,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 121,
          "ouvert": 1,
          "categoryId": 27,
          "temperature": "до +20°С",
          "subCategoryId": 111,
          "dureeDeConservation": "3 heures",
          "indicateur": 0
        },
        {
          "id": 122,
          "ouvert": 1,
          "categoryId": 27,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 112,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id": 123,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 113,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 124,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 114,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 125,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 115,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 126,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 116,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 127,
          "ouvert": 1,
          "categoryId": 29,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 117,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 128,
          "ouvert": 1,
          "categoryId": 29,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 118,
          "dureeDeConservation": "168 heures",
          "indicateur": 0
        },
        {
          "id": 129,
          "ouvert": 1,
          "categoryId": 29,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 119,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 130,
          "ouvert": 1,
          "categoryId": 29,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 120,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 131,
          "ouvert": 1,
          "categoryId": 30,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 121,
          "dureeDeConservation": "48 jours",
          "indicateur": 0
        },
        {
          "id": 132,
          "ouvert": 1,
          "categoryId": 30,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 122,
          "dureeDeConservation": "48 jours",
          "indicateur": 0
        },
        {
          "id": 133,
          "ouvert": 1,
          "categoryId": 30,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 123,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 134,
          "ouvert": 1,
          "categoryId": 30,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 124,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 135,
          "ouvert": 1,
          "categoryId": 30,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 125,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 136,
          "ouvert": 1,
          "categoryId": 30,
          "temperature": "до +20°С",
          "subCategoryId": 125,
          "dureeDeConservation": "18 mois",
          "indicateur": 0
        },
        {
          "id": 137,
          "ouvert": 1,
          "categoryId": 30,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 126,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 138,
          "ouvert": 1,
          "categoryId": 30,
          "temperature": "до +20°С",
          "subCategoryId": 126,
          "dureeDeConservation": "18 mois",
          "indicateur": 0
        },
        {
          "id": 139,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 127,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 140,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 128,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 141,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 129,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 142,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 130,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 143,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 131,
          "dureeDeConservation": "6 mois",
          "indicateur": 0
        },
        {
          "id": 144,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 132,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 145,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 133,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id": 146,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 134,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 147,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 135,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 148,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "до +20°С",
          "subCategoryId": 136,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 149,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 136,
          "dureeDeConservation": "15 jours",
          "indicateur": 0
        },
        {
          "id": 150,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 137,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 151,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 138,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        {
          "id": 152,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 139,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 153,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 140,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id": 154,
          "ouvert": 1,
          "categoryId": 31,
          "temperature": "до +20°С",
          "subCategoryId": 140,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 155,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "до +20°С",
          "subCategoryId": 141,
          "dureeDeConservation": "18 mois",
          "indicateur": 0
        },
        {
          "id": 156,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 142,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        {
          "id": 157,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "до +20°С",
          "subCategoryId": 143,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id": 158,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "до +20°С",
          "subCategoryId": 144,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        {
          "id": 159,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 145,
          "dureeDeConservation": "365 jours",
          "indicateur": 0
        },
        {
          "id": 160,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "до +20°С",
          "subCategoryId": 146,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        {
          "id": 161,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "до +20°С",
          "subCategoryId": 147,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id": 162,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "до +20°С",
          "subCategoryId": 148,
          "dureeDeConservation": "4 annees",
          "indicateur": 0
        },
        {
          "id": 163,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "до +20°С",
          "subCategoryId": 149,
          "dureeDeConservation": "",
          "indicateur": 0
        },
        {
          "id": 164,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "до +20°С",
          "subCategoryId": 150,
          "dureeDeConservation": "18 mois",
          "indicateur": 0
        },
        {
          "id": 165,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "до +20°С",
          "subCategoryId": 151,
          "dureeDeConservation": "12 mois",
          "indicateur": 0
        },
        {
          "id": 166,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "до +20°С",
          "subCategoryId": 152,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id": 167,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "до +20°С",
          "subCategoryId": 153,
          "dureeDeConservation": "6 mois",
          "indicateur": 0
        },
        {
          "id": 168,
          "ouvert": 1,
          "categoryId": 32,
          "temperature": "до +20°С",
          "subCategoryId": 154,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id": 169,
          "ouvert": 1,
          "categoryId": 33,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 155,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 170,
          "ouvert": 1,
          "categoryId": 33,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 156,
          "dureeDeConservation": "168 heures",
          "indicateur": 0
        },
        {
          "id": 171,
          "ouvert": 1,
          "categoryId": 33,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 157,
          "dureeDeConservation": "168 heures",
          "indicateur": 0
        },
        {
          "id": 172,
          "ouvert": 1,
          "categoryId": 33,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 158,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 173,
          "ouvert": 1,
          "categoryId": 34,
          "temperature": "до +20°С",
          "subCategoryId": 159,
          "dureeDeConservation": "36 mois",
          "indicateur": 0
        },
        {
          "id": 174,
          "ouvert": 1,
          "categoryId": 34,
          "temperature": "до +20°С",
          "subCategoryId": 160,
          "dureeDeConservation": "24 mois",
          "indicateur": 0
        },
        {
          "id": 175,
          "ouvert": 1,
          "categoryId": 35,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 161,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 176,
          "ouvert": 1,
          "categoryId": 35,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 162,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 177,
          "ouvert": 1,
          "categoryId": 35,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 163,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 178,
          "ouvert": 0,
          "categoryId": 36,
          "temperature": "-18°С",
          "subCategoryId": 164,
          "dureeDeConservation": "24 mois",
          "indicateur": 1
        },
        {
          "id": 179,
          "ouvert": 0,
          "categoryId": 37,
          "temperature": "-18°С",
          "subCategoryId": 165,
          "dureeDeConservation": "180 jours",
          "indicateur": 1
        },
        {
          "id": 180,
          "ouvert": 1,
          "categoryId": 37,
          "temperature": "до +20°С",
          "subCategoryId": 165,
          "dureeDeConservation": "30 minutes",
          "indicateur": 0
        },
        {
          "id": 181,
          "ouvert": 1,
          "categoryId": 38,
          "temperature": "до +20°С",
          "subCategoryId": 166,
          "dureeDeConservation": "21 jours",
          "indicateur": 0
        },
        {
          "id": 182,
          "ouvert": 1,
          "categoryId": 38,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 167,
          "dureeDeConservation": "10 jours",
          "indicateur": 0
        },
        {
          "id": 183,
          "ouvert": 0,
          "categoryId": 38,
          "temperature": "-18°С",
          "subCategoryId": 168,
          "dureeDeConservation": "180 jours",
          "indicateur": 1
        },
        {
          "id": 184,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 169,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 185,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 170,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 186,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 171,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 187,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 172,
          "dureeDeConservation": "10 jours",
          "indicateur": 0
        },
        {
          "id": 188,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 173,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 189,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 174,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 190,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 175,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 191,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 176,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 192,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 177,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 193,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 178,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 194,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 179,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 195,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 180,
          "dureeDeConservation": "120 jours",
          "indicateur": 0
        },
        {
          "id": 196,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 181,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id": 197,
          "ouvert": 1,
          "categoryId": 39,
          "temperature": "до +20°С",
          "subCategoryId": 181,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 198,
          "ouvert": 1,
          "categoryId": 40,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 182,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 199,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 183,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 200,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 184,
          "dureeDeConservation": "24 heures ",
          "indicateur": 0
        },
        {
          "id": 201,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 185,
          "dureeDeConservation": "24 heures ",
          "indicateur": 0
        },
        {
          "id": 202,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 186,
          "dureeDeConservation": "24 heures ",
          "indicateur": 0
        },
        {
          "id": 203,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 187,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 204,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 188,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 205,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 189,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 206,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 190,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 207,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 191,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 208,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 192,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 209,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 193,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 210,
          "ouvert": 1,
          "categoryId": 27,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 194,
          "dureeDeConservation": "24 heures ",
          "indicateur": 0
        },
        {
          "id": 211,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 195,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 212,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 196,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 213,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 197,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 214,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 198,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 215,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 199,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 216,
          "ouvert": 1,
          "categoryId": 41,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 200,
          "dureeDeConservation": "120 heures",
          "indicateur": 0
        },
        {
          "id": 217,
          "ouvert": 1,
          "categoryId": 28,
          "temperature": "до +20°С",
          "subCategoryId": 202,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 218,
          "ouvert": 1,
          "categoryId": 42,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 203,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 219,
          "ouvert": 1,
          "categoryId": 42,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 204,
          "dureeDeConservation": "12 jours",
          "indicateur": 0
        },
        {
          "id": 220,
          "ouvert": 1,
          "categoryId": 42,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 205,
          "dureeDeConservation": "24 heures ",
          "indicateur": 0
        },
        {
          "id": 221,
          "ouvert": 1,
          "categoryId": 43,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 206,
          "dureeDeConservation": "24 heures ",
          "indicateur": 0
        },
        {
          "id": 222,
          "ouvert": 1,
          "categoryId": 43,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 207,
          "dureeDeConservation": "18 heures ",
          "indicateur": 0
        },
        {
          "id": 223,
          "ouvert": 1,
          "categoryId": 43,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 208,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 224,
          "ouvert": 1,
          "categoryId": 43,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 209,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 225,
          "ouvert": 1,
          "categoryId": 43,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 210,
          "dureeDeConservation": "32 heures",
          "indicateur": 0
        },
        {
          "id": 226,
          "ouvert": 1,
          "categoryId": 44,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 211,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 227,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 212,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 228,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 213,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 229,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 214,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 230,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 215,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 231,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 216,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 232,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 217,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 233,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 218,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 234,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 219,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 235,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 220,
          "dureeDeConservation": "24 heures ",
          "indicateur": 0
        },
        {
          "id": 236,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 221,
          "dureeDeConservation": "4 heures ",
          "indicateur": 0
        },
        {
          "id": 237,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 222,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 238,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 223,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 239,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 224,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 240,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 225,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 241,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 226,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 242,
          "ouvert": 1,
          "categoryId": 45,
          "temperature": "до +20°С",
          "subCategoryId": 227,
          "dureeDeConservation": "4 heures",
          "indicateur": 0
        },
        {
          "id": 243,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+10°С",
          "subCategoryId": 228,
          "dureeDeConservation": "20 jours",
          "indicateur": 0
        },
        {
          "id": 244,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+10°С",
          "subCategoryId": 234,
          "dureeDeConservation": "60 jours",
          "indicateur": 0
        },
        {
          "id": 245,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+10°С",
          "subCategoryId": 235,
          "dureeDeConservation": "60 jours",
          "indicateur": 0
        },
        {
          "id": 246,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "0+10°С",
          "subCategoryId": 229,
          "dureeDeConservation": "10 jours",
          "indicateur": 0
        },
        {
          "id": 247,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "0+10°С",
          "subCategoryId": 243,
          "dureeDeConservation": "10 jours",
          "indicateur": 0
        },
        {
          "id": 248,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+6°С",
          "subCategoryId": 230,
          "dureeDeConservation": "20 jours",
          "indicateur": 0
        },
        {
          "id": 249,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+6°С",
          "subCategoryId": 232,
          "dureeDeConservation": "60 jours",
          "indicateur": 0
        },
        {
          "id": 250,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+6°С",
          "subCategoryId": 236,
          "dureeDeConservation": "7 jours",
          "indicateur": 0
        },
        {
          "id": 251,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+6°С",
          "subCategoryId": 237,
          "dureeDeConservation": "90 jours",
          "indicateur": 0
        },
        {
          "id": 252,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+6°С",
          "subCategoryId": 238,
          "dureeDeConservation": "60 jours",
          "indicateur": 0
        },
        {
          "id": 253,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+6°С",
          "subCategoryId": 240,
          "dureeDeConservation": "15 jours",
          "indicateur": 0
        },
        {
          "id": 254,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+6°С",
          "subCategoryId": 241,
          "dureeDeConservation": "50 jours",
          "indicateur": 0
        },
        {
          "id": 255,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+6°С",
          "subCategoryId": 242,
          "dureeDeConservation": "90 jours",
          "indicateur": 0
        },
        {
          "id": 256,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+6°С",
          "subCategoryId": 246,
          "dureeDeConservation": "14 jours",
          "indicateur": 0
        },
        {
          "id": 257,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+6°С",
          "subCategoryId": 247,
          "dureeDeConservation": "21 jours",
          "indicateur": 0
        },
        {
          "id": 258,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+0+25°С",
          "subCategoryId": 231,
          "dureeDeConservation": "20 jours",
          "indicateur": 0
        },
        {
          "id": 259,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+14°С",
          "subCategoryId": 233,
          "dureeDeConservation": "14 jours",
          "indicateur": 0
        },
        {
          "id": 260,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+0+6°С",
          "subCategoryId": 244,
          "dureeDeConservation": "20 jours",
          "indicateur": 0
        },
        {
          "id": 261,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+0+6°С",
          "subCategoryId": 245,
          "dureeDeConservation": "180 jours",
          "indicateur": 0
        },
        {
          "id": 262,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+6°С",
          "subCategoryId": 246,
          "dureeDeConservation": "14 jours",
          "indicateur": 0
        },
        {
          "id": 263,
          "ouvert": 1,
          "categoryId": 46,
          "temperature": "+2+6°С",
          "subCategoryId": 247,
          "dureeDeConservation": "21 jours",
          "indicateur": 0
        },
        {
          "id": 264,
          "ouvert": 1,
          "categoryId": 47,
          "temperature": "x",
          "subCategoryId": 248,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 265,
          "ouvert": 1,
          "categoryId": 47,
          "temperature": "x",
          "subCategoryId": 249,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 266,
          "ouvert": 1,
          "categoryId": 47,
          "temperature": "x",
          "subCategoryId": 250,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 267,
          "ouvert": 1,
          "categoryId": 47,
          "température": "x",
          "subCategoryId": 251,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 268,
          "ouvert": 1,
          "categoryId": 47,
          "température": "x",
          "subCategoryId": 252,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 269,
          "ouvert": 1,
          "categoryId": 47,
          "température": "x",
          "subCategoryId": 253,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 270,
          "ouvert": 1,
          "categoryld": 47,
          "température": "x",
          "subCategoryId": 254,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 271,
          "ouvert": 1,
          "categoryld": 47,
          "température": "x",
          "subCategoryId": 255,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 272,
          "ouvert": 1,
          "categoryld": 47,
          "température": "x",
          "subCategoryId": 256,
          "dureeDeConservation": "12 heures",
          "indicateur": 0
        },
        {
          "id": 273,
          "ouvert": 1,
          "categoryld": 47,
          "température": "x",
          "subCategoryId": 257,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 274,
          "ouvert": 1,
          "categoryld": 47,
          "température": "x",
          "subCategoryId": 258,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 275,
          "ouvert": 1,
          "categoryld": 47,
          "température": "x",
          "subCategoryId": 259,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 276,
          "ouvert": 1,
          "categoryId": 47,
          "température": "x",
          "subCategoryId": 260,
          "dureeDeConservation": "36 heures",
          "indicateur": 0
        },
        {
          "id": 277,
          "ouvert": 1,
          "categoryld": 47,
          "température": "x",
          "subCategoryId": 261,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 278,
          "ouvert": 1,
          "categoryld": 47,
          "température": "x",
          "subCategoryId": 262,
          "dureeDeConservation": "18 heures",
          "indicateur": 0
        },
        {
          "id": 279,
          "ouvert": 1,
          "categoryld": 47,
          "température": "x",
          "subCategoryId": 263,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 5001,
          "ouvert": 1,
          "categoryId": 47,
          "température": "x",
          "subCategoryId": 264,
          "dureeDeConservation": "24 heures",
          "indicateur": 0
        },
        {
          "id": 280,
          "ouvert": 1,
          "categoryld": 47,
          "température": "x",
          "subCategoryId": 265,
          "dureeDeConservation": "30 jours",
          "indicateur": 0
        },
        {
          "id": 281,
          "ouvert": 1,
          "categoryld": 47,
          "température": "x",
          "subCategoryId": 266,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 282,
          "ouvert": 1,
          "categoryld": 47,
          "température": "x",
          "subCategoryId": 267,
          "dureeDeConservation": "7 jours",
          "indicateur": 0
        },
        {
          "id": 283,
          "ouvert": 1,
          "categoryld": 47,
          "température": "x",
          "subCategoryId": 268,
          "dureeDeConservation": "7 jours",
          "indicateur": 0
        },
        {
          "id": 28,
          "ouvert": 1,
          "categoryId": 900,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 23,
          "dureeDeConservation": "72 heures",
          "indicateur": 0
        },
        {
          "id": 29,
          "ouvert": 1,
          "categoryId": 900,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 24,
          "dureeDeConservation": "48 heures",
          "indicateur": 0
        },
        {
          "id": 30,
          "ouvert": 1,
          "categoryId": 900,
          "temperature": "от +2 до +6°С",
          "subCategoryId": 25,
          "dureeDeConservation": "21 jours",
          "indicateur": 0
        },
        {
          "id": 445,
          "ouvert": 1,
          "categoryId": 25,
          "temperature": "x",
          "subCategoryId": 444,
          "dureeDeConservation": "1 jours",
          "indicateur": 1
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
              print(
                  'Value of "ouvert" from the database: ${maps[i]['ouvert']}');
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

  static Future<List<Temperature>> getTemperaturesByCategoryId(
      int isOpen, int categoryId) async {
    try {
      Database db = await _instance.database;

      // Requête pour récupérer les températures en fonction de la catégorie
      List<Map<String, dynamic>> maps = await db.query(
        'Temperatures',
        where: 'categoryId = ? AND ouvert = ?',
        whereArgs: [categoryId, isOpen],
      );

      // Convertir les résultats en objets Temperature
      List<Temperature> temperatures = List.generate(maps.length, (i) {
        return Temperature.fromJson(maps[i]);
      });

      return temperatures;
    } catch (e) {
      if (kDebugMode) {
        print(
            'Erreur lors de la récupération des températures par catégorie : $e');
      }
      rethrow;
    }
  }

  static Future<List<SubCategory>> getSubCategoriesByFilteredCategories(
      List<Categorie> filteredCategories) async {
    try {
      Database db = await _instance.database;

      // Récupérer les IDs des catégories filtrées
      List<int> categoryIds =
          filteredCategories.map((categorie) => categorie.id).toList();

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

  static Future<List<Categorie>> getCategorieByIdCuisine(
      Cuisine cuisine) async {
    try {
      Database db = await _instance.database;

      // Ajout de l'impression de débogage
      if (kDebugMode) {
        print('getCategorieByIdCuisine - Cuisine ID: ${cuisine.id}');
      }

      // Récupérer les catégories pour une cuisine spécifique
      List<Map<String, dynamic>> maps = await db
          .query('Categories', where: 'cuisineId = ?', whereArgs: [cuisine.id]);

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

  // methode pour recuperer la duree de concervation et l'indicateur d'une sous-categorie d'une categorie
  // en fonction de la liste des temperatures

  static Future<List<dynamic>> getDurreeConcervationAndIdicator(
      List<Temperature> temperatureList) async {
    List<dynamic> resultat = [];
    try {
      // recuperation de la durree de concervation
      resultat.add(temperatureList.first.dureeDeConservation);
      // recuperation de l'indicateur
      resultat.add(temperatureList.first.indicateur);

      // Ajout d'une impression pour vérifier les résultats
      if (kDebugMode) {
        print(
            'les valeurs attentudes - Résultats- durree concervation ${resultat.first} --- indicateur ${resultat.last} ---');
      }

      return resultat;
    } catch (e) {
      if (kDebugMode) {
        print(
            'Erreur lors de la récupération des informations durree de concervation et indicateur : $e');
      }
      rethrow;
    }
  }

  //recuperer temperature par categoryId , subcategoryId , isOpen
  static Future<List<Temperature>>
      getTemperaturesByCategoryIdSubCategoryIdIsOpen(
          int subcategoryId, int isOpen) async {
    try {
      Database db = await _instance.database;
      if (kDebugMode) {
        print(
            'les donnees entre pour le filtrage dans la fonction filtre : subcategory  $subcategoryId  --isOpen $isOpen');
      }
      // Requête pour récupérer les températures en fonction de la catégorie, du sous-catégorie et de l'ouverture
      List<Map<String, dynamic>> maps = await db.query(
        'Temperatures',
        where: 'subcategoryId = ? AND ouvert = ?',
        whereArgs: [subcategoryId, isOpen],
      );

      // Convertir les résultats en objets Temperature
      List<Temperature> temperatures = List.generate(maps.length, (i) {
        return Temperature.fromJson(maps[i]);
      });
      if (kDebugMode) {
        print(
            'les donnees de la liste temperature dans son ensemble  : ${temperatures.toString()}');
      }
      return temperatures;
    } catch (e) {
      if (kDebugMode) {
        print(
            'Erreur lors de la récupération des températures par catégorie, sous-catégorie et ouverture : $e');
      }
      rethrow;
    }
  }

  static Future<List<Categorie>> getCategoryFilter(
      List<Temperature> temperatureList, List<Categorie> allCategories) async {
    try {
      // Ajout de l'impression de débogage
      if (kDebugMode) {
        print(
            'getCategoryFilter - TemperatureList: $temperatureList, AllCategories: $allCategories');
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
