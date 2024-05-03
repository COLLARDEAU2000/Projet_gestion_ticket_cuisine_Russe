// ignore_for_file: use_build_context_synchronously, non_constant_identifier_names, unnecessary_brace_in_string_interps

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinlintsa/models/category_cuisine.dart';
import 'package:grinlintsa/models/cuisine.dart';
import 'package:grinlintsa/models/cook.dart';
import 'package:grinlintsa/models/temperature.dart';
import 'package:grinlintsa/models/sub_category.dart';
import 'package:grinlintsa/services/calculator_date.dart';
import 'package:grinlintsa/services/database_helper.dart';
import 'package:grinlintsa/services/PrintManager.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart'; // Import de la classe PrinterManager

class CreateTicketScreen extends StatefulWidget {
  final Cuisine cuisine;
  final Cook cook;

  const CreateTicketScreen(
      {Key? key, required this.cuisine, required this.cook})
      : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CreateTicketScreenState createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  bool isOpening = false;
  List<Categorie> categories = [];
  List<SubCategory> subCategories = [];
  List<dynamic> listeTicket = []; // Initialisation de la liste dynamique ici
  List<dynamic> listeInfosDureeConcervationEtIndicateur =
      []; // Initialisation de la liste
  List<Temperature> ListTemperaturesTicketCreation =
      []; // Initialisation de la liste
  int quantity = 1; // Déclaration de la variable quantity
  String dateOne = ""; // Déclaration de la date 1
  String dateTwo = ""; // Déclaration de la date 2
  String dateThree = ""; // Déclaration de la date 3
  @override
  void initState() {
    super.initState();
    _updateCategories();
  }

  

  Future<void> _handlePrint(List<dynamic> infosTickets) async {
    // Vérifier si le Bluetooth est activé
    bool isBluetoothEnabled = await PrinterManager.checkBluetooth();
    if (!isBluetoothEnabled) {
      // Afficher une boîte de dialogue demandant à l'utilisateur d'activer le Bluetooth
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Bluetooth désactivé'),
            content: const Text('Veuillez activer le Bluetooth pour imprimer.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer la boîte de dialogue
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return; // Sortir de la fonction si le Bluetooth n'est pas activé
    }

    // Si le Bluetooth est activé, récupérer les informations de l'imprimante
    List<BluetoothInfo> printerInfo =
        await PrinterManager.checkConnectionPrinter();

    // Lancer l'impression
    bool isPrinted = await PrinterManager.impression(printerInfo, infosTickets);
    if (isPrinted) {
      // Afficher un message de confirmation après impression réussie si nécessaire
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impression réussie')),
      );
    } else {
      // Gérer le cas où l'impression a échoué, si nécessaire
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'impression')),
      );
    }
  }

  Future<void> _updateCategories() async {
    try {
      if (kDebugMode) {
        print('_updateCategories - IsOpening: $isOpening');
      }

      List<Temperature> temperatures =
          await DatabaseHelper.getTemperaturesByOpen(isOpening ? 1 : 0);
      /*if (kDebugMode) {
        print('Temperature List: $temperatures');
      }*/

      List<Categorie> allCategories =
          await DatabaseHelper.getCategorieByIdCuisine(widget.cuisine);
      /*if (kDebugMode) {
        print('All Categories: $allCategories');
      }*/

      List<Categorie> filteredCategories =
          await DatabaseHelper.getCategoryFilter(temperatures, allCategories);
      /*if (kDebugMode) {
        print('Filtered Categories: $filteredCategories');
      }*/

      setState(() {
        categories = filteredCategories;
      });
    } catch (e) {
      /*if (kDebugMode) {
        print('Erreur lors de la mise à jour des catégories : $e');
      }*/
    }
  }

  Future<void> _updateSubCategories(int categoryId) async {
    try {
      List<Temperature> temperatures =
          await DatabaseHelper.getTemperaturesByCategoryId(categoryId);
      List<int> subCategoryIds =
          temperatures.map((temp) => temp.subCategoryId).toList();
      List<SubCategory> filteredSubCategories =
          await DatabaseHelper.getSubCategoriesByIds(subCategoryIds);

      setState(() {
        subCategories = filteredSubCategories;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour des sous-catégories : $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un ticket'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Switch(
                  value: isOpening,
                  onChanged: (value) {
                    setState(() {
                      isOpening = value;
                      _updateCategories();
                    });
                  },
                ),
                const SizedBox(width: 8.0),
                const Text('Ouverture'),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          title: Text(categories[index].name),
                          onTap: () {
                            _updateSubCategories(categories[index].id);
                          },
                        ),
                      );
                    },
                  ),
                ),
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
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        color: Colors.orange,
                        child: ListTile(
                          title: Text(subCategories[index].name),
                          onTap: () {
                            // Ajoutez ici l'action que vous souhaitez effectuer lorsqu'une sous-catégorie est sélectionnée.
                            listeTicket.add(widget.cook
                                .name); // Ajoute le nom du cuisinier à la liste
                            listeTicket.add(subCategories[index]
                                .name); // Ajoute le nom de la sous-catégorie sélectionnée à la liste
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Info ticket'),
                                  content: StatefulBuilder(
                                    builder: (BuildContext context,
                                        StateSetter setState) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              'Nom du produit: ${subCategories[index].name}'),
                                          Text(
                                              'Catégorie: ${categories[index].name}'),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                onPressed: () {
                                                  setState(() {
                                                    if (quantity > 1) {
                                                      quantity--;
                                                    }
                                                  });
                                                },
                                              ),
                                              SizedBox(
                                                width: 100,
                                                child: TextField(
                                                  textAlign: TextAlign.center,
                                                  decoration:
                                                      const InputDecoration(
                                                    border:
                                                        OutlineInputBorder(),
                                                  ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  controller:
                                                      TextEditingController(
                                                          text: quantity
                                                              .toString()),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      quantity =
                                                          int.tryParse(value) ??
                                                              1;
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
                                        // Ajoutez ici la logique pour l'impression du ticket
                                        listeTicket.add(
                                            quantity); // Ajoute le ticket à la liste
                                        // Recuperer indicateur et la durree de concervation
                                        if (kDebugMode) {
                                          print(
                                              'Affichage des informations pour la fonction : subcategorie ${subCategories[index].id}-- categori: ${categories[index].id} -- open: ${isOpening}');
                                        }
                                        ListTemperaturesTicketCreation =
                                            await DatabaseHelper
                                                .getTemperaturesByCategoryIdSubCategoryIdIsOpen(
                                                    subCategories[index].id,
                                                    isOpening ? 1 : 0);
                                        listeInfosDureeConcervationEtIndicateur =
                                            await DatabaseHelper
                                                .getDurreeConcervationAndIdicator(
                                                    ListTemperaturesTicketCreation);
                                        // Utiliser calculator pour recuperer les dates
                                        listeInfosDureeConcervationEtIndicateur =
                                            Calculator.calculateDate(
                                                listeInfosDureeConcervationEtIndicateur
                                                    .first,
                                                listeInfosDureeConcervationEtIndicateur
                                                    .last);

                                        // verification de la taille de la list
                                        if (listeInfosDureeConcervationEtIndicateur
                                                .length ==
                                            2) {
                                          // recuperation de la premiere date
                                          dateOne =
                                              listeInfosDureeConcervationEtIndicateur
                                                  .first;
                                          // recuperation de la deuxieme date
                                          dateTwo =
                                              listeInfosDureeConcervationEtIndicateur[
                                                  1];

                                          // Ajouter les dates dans liste Tickets
                                          listeTicket.add(dateOne);
                                          listeTicket.add(dateTwo);
                                        } else {
                                          // recuperation de la premiere date
                                          dateOne =
                                              listeInfosDureeConcervationEtIndicateur
                                                  .first;
                                          // recuperation de la deuxieme date
                                          dateTwo =
                                              listeInfosDureeConcervationEtIndicateur[
                                                  1];
                                          // recuperation de la troisieme date
                                          dateThree =
                                              listeInfosDureeConcervationEtIndicateur[
                                                  2];

                                          // Ajouter les dates dans liste Tickets
                                          listeTicket.add(dateOne);
                                          listeTicket.add(dateTwo);
                                          listeTicket.add(dateThree);
                                        }

                                        // affiche du resultat en console
                                        if (kDebugMode) {
                                          print(
                                              'Affichage des informations de la liste : ${listeTicket}');
                                        }
                                        //verifier la connextion a l'imprimente
                                        // Lancer l'impression
                                        Navigator.pop(
                                            context); // Ferme la boîte de dialogue
                                        // Appeler la fonction _handlePrint lors du clic sur le bouton
                                        await _handlePrint(listeTicket);
                                        Navigator.pop(
                                            context); // Fermer la boîte de dialogue
                                      },
                                      child: const Text('Imprimer'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
