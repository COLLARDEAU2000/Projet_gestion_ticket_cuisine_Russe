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
  bool isOpening = true;
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
  // instance ticket manager
  final TicketManager _ticketManager = new TicketManager();

  @override
  void initState() {
    super.initState();
    _updateCategories();
  }

  Future<void> _updateCategories() async {
    try {
      if (kDebugMode) {
        print('_updateCategories - IsOpening: $isOpening');
      }

      List<Temperature> temperatures =
          await DatabaseHelper.getTemperaturesByOpen(isOpening ? 1 : 1);
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
  return GestureDetector(
    // Gérer le geste de glissement horizontal pour revenir en arrière
    onHorizontalDragEnd: (details) {
      if (details.primaryVelocity! > 0) {
        Navigator.of(context).pop();
      }
    },
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Supprimer automatiquement le bouton de retour en arrière
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
        centerTitle: true, // Centrer le texte dans la AppBar
      ),
      bottomNavigationBar: const BottomAppBar(
        color: Colors.white, // Couleur de fond du BottomNavigationBar
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              // Ajoutez ici l'action que vous souhaitez effectuer lorsqu'une sous-catégorie est sélectionnée.
                              listeTicket.add(widget.cook.name); // Ajoute le nom du cuisinier à la liste
                              listeTicket.add(subCategories[index].name); // Ajoute le nom de la sous-catégorie sélectionnée à la liste
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
                                                    decoration: const InputDecoration(
                                                      border: OutlineInputBorder(),
                                                    ),
                                                    keyboardType: TextInputType.number,
                                                    controller: TextEditingController(text: quantity.toString()),
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
                                          // Ajoutez ici la logique pour l'impression du ticket
                                          listeTicket.add(quantity); // Ajoute le ticket à la liste
                                          // Recuperer indicateur et la durree de concervation
                                          if (kDebugMode) {
                                            print(
                                                'Affichage des informations pour la fonction : subcategorie ${subCategories[index].id}-- categori: ${categories[index].id} -- open: ${isOpening}');
                                          }
                                          if (kDebugMode) {
                                            print(
                                                'Affichage index :  ${index}');
                                          }
                                          ListTemperaturesTicketCreation =
                                              await DatabaseHelper.getTemperaturesByCategoryIdSubCategoryIdIsOpen(
                                                  subCategories[index].id, isOpening ? 1 : 1);
                                          listeInfosDureeConcervationEtIndicateur =
                                              await DatabaseHelper.getDurreeConcervationAndIdicator(
                                                  ListTemperaturesTicketCreation);
                                          // Utiliser calculator pour recuperer les dates
                                          listeInfosDureeConcervationEtIndicateur =
                                              Calculator.calculateDate(
                                                  listeInfosDureeConcervationEtIndicateur.first,
                                                  listeInfosDureeConcervationEtIndicateur.last);

                                          // verification de la taille de la list
                                          if (listeInfosDureeConcervationEtIndicateur.length == 2) {
                                            // recuperation de la premiere date
                                            dateOne = listeInfosDureeConcervationEtIndicateur.first;
                                            // recuperation de la deuxieme date
                                            dateTwo = listeInfosDureeConcervationEtIndicateur[1];

                                            // Ajouter les dates dans liste Tickets
                                            listeTicket.add(dateOne);
                                            listeTicket.add(dateTwo);
                                          } else {
                                            // recuperation de la premiere date
                                            dateOne = listeInfosDureeConcervationEtIndicateur.first;
                                            // recuperation de la deuxieme date
                                            dateTwo = listeInfosDureeConcervationEtIndicateur[1];
                                            // recuperation de la troisieme date
                                            dateThree = listeInfosDureeConcervationEtIndicateur[2];

                                            // Ajouter les dates dans liste Tickets
                                            listeTicket.add(dateOne);
                                            listeTicket.add(dateTwo);
                                            listeTicket.add(dateThree);
                                          }

                                          // affiche du resultat en console
                                          if (kDebugMode) {
                                            print('Affichage des informations de la liste : ${listeTicket}');
                                          }
                                          //verifier la connextion a l'imprimente
                                          // Lancer l'impression
                                          Navigator.pop(context); // Ferme la boîte de dialogue
                                          // Vérifier si le Bluetooth est activé
                                          bool? isBluetoothActive = await _ticketManager.isBluetoothActive();
                                          if (kDebugMode) {
                                            print('VOICI LA VALEUR RECHERCHER : ${isBluetoothActive}');
                                          }
                                          if (isBluetoothActive!) {
                                            try {
                                              // Imprimer le ticket en utilisant la méthode printTicket du TicketManager
                                              await _ticketManager.printTicket(listeTicket);
                                            } catch (e) {
                                              // Afficher une boîte de dialogue en cas d'erreur lors de l'impression
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text('Erreur d\'impression'),
                                                    content: Text('Une erreur s\'est produite lors de l\'impression du ticket : $e'),
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
                                          } else {
                                            // Afficher un dialogue indiquant que le Bluetooth est désactivé
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text('Bluetooth désactivé'),
                                                  content: const Text('Veuillez activer le Bluetooth pour imprimer.'),
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
                                        },
                                        child: const Text('Печать'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        );
                      } catch (e) {
                        // Gérer les erreurs lors de l'accès à la liste subCategories
                        if (kDebugMode) {
                          print("Erreur lors de l'accès à la liste subCategories : $e");
                        }
                        return Container(); // Ou tout autre widget de remplacement
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

}
