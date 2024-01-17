import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:grinlintsa/models/category_cuisine.dart';
import 'package:grinlintsa/models/cuisine.dart';
import 'package:grinlintsa/models/cook.dart';
import 'package:grinlintsa/models/temperature.dart';
import 'package:grinlintsa/models/sub_category.dart';
import 'package:grinlintsa/services/database_helper.dart';

class CreateTicketScreen extends StatefulWidget {
  final Cuisine cuisine;
  final Cook cook;

  const CreateTicketScreen({Key? key, required this.cuisine, required this.cook}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CreateTicketScreenState createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  bool isOpening = false;
  List<Categorie> categories = [];
  List<SubCategory> subCategories = [];

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

      List<Temperature> temperatures = await DatabaseHelper.getTemperaturesByOpen(isOpening ? 1 : 0);
      if (kDebugMode) {
        print('Temperature List: $temperatures');
      }

      List<Categorie> allCategories = await DatabaseHelper.getCategorieByIdCuisine(widget.cuisine);
      if (kDebugMode) {
        print('All Categories: $allCategories');
      }

      List<Categorie> filteredCategories = await DatabaseHelper.getCategoryFilter(temperatures, allCategories);
      if (kDebugMode) {
        print('Filtered Categories: $filteredCategories');
      }

      setState(() {
        categories = filteredCategories;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour des catégories : $e');
      }
    }
  }

  Future<void> _updateSubCategories(int categoryId) async {
    try {
      List<Temperature> temperatures = await DatabaseHelper.getTemperaturesByCategoryId(categoryId);
      List<int> subCategoryIds = temperatures.map((temp) => temp.subCategoryId).toList();
      List<SubCategory> filteredSubCategories = await DatabaseHelper.getSubCategoriesByIds(subCategoryIds);

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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
