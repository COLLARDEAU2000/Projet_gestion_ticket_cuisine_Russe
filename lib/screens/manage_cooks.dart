import 'package:flutter/material.dart';
import 'package:grinlintsa/models/cuisine.dart';
import 'package:grinlintsa/models/cook.dart';
import 'package:grinlintsa/services/database_helper.dart';

class ManageCooks extends StatefulWidget {
  final Cuisine cuisine;

  const ManageCooks({Key? key, required this.cuisine}) : super(key: key);

  @override
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
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity! > 0) {
          // Glissement vers la droite, effectuer l'action de retour en arrière
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Управление кухней',
            style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          automaticallyImplyLeading:
              false, // Désactive le bouton de retour automatique
          backgroundColor: Colors.white,
          leading: Image.asset(
            'assets/logorussie.png',
            width: 40,
            height: 40,
          ),
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
        body: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'список поваров',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16.0),
                  Expanded(
                    child: FutureBuilder<List<Cook>>(
                      future: DatabaseHelper().getCooks(widget.cuisine),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError ||
                            snapshot.data!.isEmpty) {
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
            Positioned(
              top: 16.0,
              right: 16.0,
              child: FloatingActionButton(
                onPressed: () async {
                  await _showAddCookDialog(context);
                  // Actualisez l'affichage après l'ajout
                  setState(() {});
                },
                backgroundColor: Colors.red, // Couleur de fond du bouton
                child: Icon(
                  Icons.add,
                  color: Colors.yellow, // Couleur de l'icône
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookCard(BuildContext context, Cook cook) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: const Icon(Icons.person),
        title: Text(
          cook.name,
          style: const TextStyle(
              fontSize: 22, color: Colors.black, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          cook.speciality,
          style: const TextStyle(
              fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
        ),
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
      child: Text('нет повара.'),
    );
  }

  Future<void> _showAddCookDialog(BuildContext context) async {
    String newCookName = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('добавить повара'),
          content: Column(
            children: [
              TextField(
                controller: _newCookNameController,
                decoration: const InputDecoration(labelText: 'имя повара'),
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
              child: const Text('Отмена'),
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
              child: const Text('добавить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(
      BuildContext context, Cook cook) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Подтверждение удаления'),
          content:
              const Text('Вы уверены, что хотите избавиться от этого повара?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
              },
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseHelper().deleteCook(widget.cuisine, cook);
                // Actualiser l'affichage après la suppression
                setState(() {});
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(); // Fermer la boîte de dialogue
              },
              child: const Text('удалить'),
            ),
          ],
        );
      },
    );
  }
}
