import 'package:flutter/material.dart';
import 'package:grinlintsa/models/cook.dart';
import 'package:grinlintsa/models/cuisine.dart';
import 'package:grinlintsa/services/database_helper.dart';

class ManageCooks extends StatefulWidget {
  final Cuisine cuisine;

  const ManageCooks({Key? key, required this.cuisine}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ManageCooksState createState() => _ManageCooksState();
}

class _ManageCooksState extends State<ManageCooks> {
  final TextEditingController _newCookNameController = TextEditingController();

  @override
  void dispose() {
    _newCookNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Cuisiniers'),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Liste des Cuisiniers',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<Cook>>(
                future: DatabaseHelper().getCooks(widget.cuisine),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  } else {
                    List<Cook> cooksList = snapshot.data!;

                    return ListView.builder(
                      itemCount: cooksList.length,
                      itemBuilder: (context, index) {
                        return _buildCookCard(context, cooksList[index]);
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _showAddCookDialog(context);
          // Actualisez l'affichage après l'ajout
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCookCard(BuildContext context, Cook cook) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(cook.name),
        subtitle: Text(cook.speciality),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            _showDeleteConfirmationDialog(context, cook);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('Aucun cuisinier disponible.'),
    );
  }

  Future<void> _showAddCookDialog(BuildContext context) async {
    String newCookName = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter un cuisinier'),
          content: Column(
            children: [
              TextField(
                controller: _newCookNameController,
                decoration:
                    const InputDecoration(labelText: 'Nom du cuisinier'),
                onChanged: (value) {
                  newCookName = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseHelper().insertCook(
                  Cook(
                    name: newCookName,
                    speciality: widget.cuisine.name,
                    cuisineId: widget.cuisine.id,
                  ),
                );
                // Actualisez l'affichage après l'ajout
                setState(() {});
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                _newCookNameController.clear();
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, Cook cook) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation de suppression'),
          content: const Text('Êtes-vous sûr de vouloir supprimer ce cuisinier ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseHelper().deleteCook(widget.cuisine, cook);
                // Actualiser l'affichage après la suppression
                setState(() {});
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }
}
