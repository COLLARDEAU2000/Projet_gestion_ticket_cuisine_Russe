// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_new

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinlintsa/models/category_cuisine.dart';
import 'package:grinlintsa/models/cuisine.dart';
import 'package:grinlintsa/models/cook.dart';
import 'package:grinlintsa/models/temperature.dart';
import 'package:grinlintsa/models/sub_category.dart';
import 'package:grinlintsa/services/calculator_date.dart';
import 'package:grinlintsa/services/database_helper.dart';
import 'package:grinlintsa/services/printerManager.dart';

class CreateTicketScreen1 extends StatefulWidget {
  final Cuisine cuisine;
  final Cook cook;

  const CreateTicketScreen1(
      {Key? key, required this.cuisine, required this.cook})
      : super(key: key);

  @override
  _CreateTicketScreen1State createState() => _CreateTicketScreen1State();
}

class _CreateTicketScreen1State extends State<CreateTicketScreen1> {
  bool isOpening = false;
  List<Categorie> categories = [];
  List<SubCategory> subCategories = [];
  List<dynamic> listeTicket = [];
  List<dynamic> listeInfosDureeConcervationEtIndicateur = [];
  List<Temperature> ListTemperaturesTicketCreation = [];
  int quantity = 1;
  String dateOne = "";
  String dateTwo = "";
  String dateThree = "";

  // Instance du TicketManager
  final TicketManager _ticketManager = TicketManager();

  @override
  void initState() {
    super.initState();
    _updateCategories();
  }

  // Met à jour la liste des catégories en fonction de l'état d'ouverture
  Future<void> _updateCategories() async {
    try {
      if (kDebugMode) print('_updateCategories - IsOpening: $isOpening');

      List<Temperature> temperatures =
          await DatabaseHelper.getTemperaturesByOpen(isOpening ? 1 : 1);
      List<Categorie> allCategories =
          await DatabaseHelper.getCategorieByIdCuisine(widget.cuisine);
      List<Categorie> filteredCategories =
          await DatabaseHelper.getCategoryFilter(temperatures, allCategories);

      setState(() {
        categories = filteredCategories;
      });
    } catch (e) {
      if (kDebugMode)
        print('Erreur lors de la mise à jour des catégories : $e');
    }
  }

  // Met à jour la liste des sous-catégories en fonction de l'état d'ouverture et de l'ID de la catégorie
  Future<void> _updateSubCategories(int isOpening, int categoryId) async {
    try {
      List<Temperature> temperatures =
          await DatabaseHelper.getTemperaturesByCategoryId(
              isOpening, categoryId);
      List<int> subCategoryIds =
          temperatures.map((temp) => temp.subCategoryId).toList();
      List<SubCategory> filteredSubCategories =
          await DatabaseHelper.getSubCategoriesByIds(subCategoryIds);

      setState(() {
        subCategories = filteredSubCategories;
      });
    } catch (e) {
      if (kDebugMode)
        print('Erreur lors de la mise à jour des sous-catégories : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          leading: Image.asset(
            'assets/logorussie.png',
            width: 40,
            height: 40,
          ),
          title: const Text(
            'Создайте маркировку',
            style: TextStyle(
                fontSize: 28, color: Colors.black, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        bottomNavigationBar: const BottomAppBar(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Приложение разработано ittechnologie.ru',
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  // Liste des catégories
                  Expanded(
                    child: ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(
                              categories[index].name,
                              style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            onTap: () {
                              _updateSubCategories(
                                  isOpening ? 1 : 1, categories[index].id);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  // Grille des sous-catégories
                  // Grille des sous-catégories
                  Expanded(
                    flex: 2,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8.0,
                        crossAxisSpacing: 8.0,
                      ),
                      itemCount: subCategories.length,
                      itemBuilder: (context, index) {
                        try {
                          return Card(
                            margin: const EdgeInsets.all(8.0),
                            color: const Color(0xFFEA3423),
                            child: ListTile(
                              title: Text(
                                subCategories[index].name,
                                style: const TextStyle(
                                    fontSize: 25,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () {
                                setState(() {
                                  listeTicket
                                      .clear(); // Réinitialise la listeTicket ici
                                  if (kDebugMode)
                                    print(
                                        "etat de la liste apres renitialisation : $listeTicket");
                                  listeTicket.add(widget.cook.name);
                                  listeTicket.add(subCategories[index].name);
                                });
                                // Continue avec les autres opérations
                                _showTicketDialog(context, index);
                              },
                            ),
                          );
                        } catch (e) {
                          if (kDebugMode)
                            print(
                                "Erreur lors de l'accès à la liste subCategories : $e");
                          return Container();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Affiche le dialogue pour la création du ticket
  // Affiche le dialogue pour la création du ticket
  void _showTicketDialog(BuildContext context, int index) {
    // Réinitialise la listeTicket et garde uniquement le nom du cuisinier
    setState(() {
      listeTicket.clear();
      listeTicket.add(widget.cook.name);
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Информация о маркировке'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Название продукта: ${subCategories[index].name}'),
                  Text('Категория: ${categories[index].name}'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (quantity > 1) quantity--;
                          });
                        },
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          controller:
                              TextEditingController(text: quantity.toString()),
                          onChanged: (value) {
                            setState(() {
                              quantity = int.tryParse(value) ?? 1;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await _handleTicketPrinting(index);

                Navigator.pop(context);
              },
              child: const Text('Печать'),
            ),
          ],
        );
      },
    );
  }

  // Gère l'impression du ticket
  // Gère l'impression du ticket
  Future<void> _handleTicketPrinting(int index) async {
    listeTicket.add(quantity);

    // Récupère les informations de durée de conservation et d'indicateur
    ListTemperaturesTicketCreation =
        await DatabaseHelper.getTemperaturesByCategoryIdSubCategoryIdIsOpen(
      subCategories[index].id,
      isOpening ? 1 : 1,
    );
    listeInfosDureeConcervationEtIndicateur =
        await DatabaseHelper.getDurreeConcervationAndIdicator(
      ListTemperaturesTicketCreation,
    );
    listeInfosDureeConcervationEtIndicateur = Calculator.calculateDate(
      subCategories[index].name,
      listeInfosDureeConcervationEtIndicateur.first,
      listeInfosDureeConcervationEtIndicateur.last,
    );

    // Mise à jour des dates
    if (listeInfosDureeConcervationEtIndicateur.length == 2) {
      dateOne = listeInfosDureeConcervationEtIndicateur.first;
      dateTwo = listeInfosDureeConcervationEtIndicateur[1];
      listeTicket.add(dateOne);
      listeTicket.add(dateTwo);
    } else {
      dateOne = listeInfosDureeConcervationEtIndicateur.first;
      dateTwo = listeInfosDureeConcervationEtIndicateur[1];
      dateThree = listeInfosDureeConcervationEtIndicateur[2];
      listeTicket.add(dateOne);
      listeTicket.add(dateTwo);
      listeTicket.add(dateThree);
    }

    // Affiche les informations de la listeTicket dans le terminal
    print('listeTicket mise à jour: $listeTicket');

    // Vérifie la connexion Bluetooth
    bool? isBluetoothActive = await _ticketManager.isBluetoothActive();
    if (isBluetoothActive!) {
      try {
        // Imprime le ticket
        await _ticketManager.printTicket(listeTicket);
      } catch (e) {
        _showErrorDialog(context, 'Erreur d\'impression',
            'Une erreur s\'est produite lors de l\'impression du ticket : $e');
      }
    } else {
      _showErrorDialog(context, 'Bluetooth désactivé',
          'Veuillez activer le Bluetooth pour imprimer.');
    }
  }

  // Affiche une boîte de dialogue d'erreur
  void _showErrorDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
