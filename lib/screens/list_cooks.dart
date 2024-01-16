// list_cooks.dart

import 'package:flutter/material.dart';
import 'package:grinlintsa/models/cook.dart';
import 'package:grinlintsa/models/cuisine.dart';
import 'package:grinlintsa/screens/create_tickets.dart';
import 'package:grinlintsa/services/database_helper.dart';

class ListCooks extends StatefulWidget {
  final Cuisine cuisine;

  const ListCooks({Key? key, required this.cuisine}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _ListCooksState createState() => _ListCooksState();
}

class _ListCooksState extends State<ListCooks> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Cuisiniers'),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
    );
  }

  Widget _buildCookCard(BuildContext context, Cook cook) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 8.0),
    child: ListTile(
      leading: const Icon(Icons.person),
      title: Text(cook.name),
      subtitle: Text(cook.speciality),
      // Ajoutez un bouton pour créer un ticket
      trailing: ElevatedButton(
        onPressed: () {
          // Naviguez vers CreateTicketScreen en passant les objets nécessaires
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateTicketScreen(
                cuisine: widget.cuisine,
                cook: cook,
              ),
            ),
          );
        },
        child: const Text('Créer un ticket'),
      ),
    ),
  );
}


  Widget _buildEmptyState() {
    return const Center(
      child: Text('Aucun cuisinier disponible.'),
    );
  }
}
