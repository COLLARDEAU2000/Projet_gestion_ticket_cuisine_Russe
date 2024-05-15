import 'package:flutter/material.dart';
import 'package:grinlintsa/models/cook.dart';
import 'package:grinlintsa/models/cuisine.dart';
import 'package:grinlintsa/screens/create_tickets.dart';
import 'package:grinlintsa/screens/create_tickets_1.dart';
import 'package:grinlintsa/services/database_helper.dart';

class ListCooks extends StatefulWidget {
  final Cuisine cuisine;

  const ListCooks({Key? key, required this.cuisine}) : super(key: key);

  @override
  _ListCooksState createState() => _ListCooksState();
}

class _ListCooksState extends State<ListCooks> {
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
            'список поваров',
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
                          return _buildCookCard(context, cooksList[index], widget.cuisine);
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCookCard(BuildContext context, Cook cook, Cuisine cuisine) {
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
      // Add a button to create a ticket
      trailing: ElevatedButton(
        onPressed: () {
          // Navigate to CreateTicketScreen passing the necessary objects
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  cuisine.name == "ПИЦЦА" || cuisine.name == "ОВОЩНОЙ ЦЕХ"
                      ? CreateTicketScreen1(
                          cuisine: widget.cuisine,
                          cook: cook,
                        )
                      : CreateTicketScreen(
                          cuisine: widget.cuisine,
                          cook: cook,
                        ),
            ),
          );
        },
        child: const Text('Создайте маркировку'),
      ),
    ),
  );
}


  Widget _buildEmptyState() {
    return const Center(
      child: Text('нет повара.'),
    );
  }
}
