// ignore_for_file: file_names

/*PARTIE TEMPERATURE
  //Charger les données initiales dans la table Temperature
  Future<void> initializeTemperatures() async {
    try {
      Database db = await database;

      List<Map<String, dynamic>> initialTemperatureData = [
        {
          "ouvert": false,
          "categoryId": 10,
          "temperature": ["-18°С"],
          "subCategoryIds": [41],
          "Duree de concervation": "180 jours",
          "indicateur": true
        }
      ];
      await db.transaction((txn) async {
        Batch batch = txn.batch();
        for (Map<String, dynamic> data in initialTemperatureData) {
          batch.rawInsert(
            'INSERT OR IGNORE INTO Temperatures (ouvert, categoryId, temperature, dureeDeConservation, indicateur) VALUES (?, ?,  ?, ?, ?)',
            [
              data['ouvert'],
              data['categoryId'],
              data['temperature'], // Convertir la liste en chaîne JSON
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
  } */