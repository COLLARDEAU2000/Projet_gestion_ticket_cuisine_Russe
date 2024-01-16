import 'package:flutter/material.dart';
import 'package:grinlintsa/models/cuisine.dart';
import 'package:grinlintsa/screens/dashboard.dart';
import 'package:grinlintsa/services/database_helper.dart';

class HomePage extends StatelessWidget {
  final List<Cuisine> cuisines;

  const HomePage({Key? key, required this.cuisines}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Cuisines'),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return _buildGrid(orientation, context);
        },
      ),
    );
  }

  Widget _buildGrid(Orientation orientation, BuildContext context) {
    return FutureBuilder<List<Cuisine>>(
      future: DatabaseHelper().getCuisines(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Erreur: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('Aucune cuisine trouvée.');
        } else {
          return GridView.builder(
            gridDelegate: _buildGridDelegate(orientation),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildCuisineCard(snapshot.data![index], context);
            },
          );
        }
      },
    );
  }

  SliverGridDelegate _buildGridDelegate(Orientation orientation) {
    if (orientation == Orientation.portrait) {
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      );
    } else {
      return const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      );
    }
  }

  Widget _buildCuisineCard(Cuisine cuisine, BuildContext context) {
    IconData iconData;

    switch (cuisine.name) {
      case 'ШАУРМА':
        iconData = Icons.fastfood;
        break;
      case 'ПИЦЦА':
        iconData = Icons.local_restaurant;
        break;
      case 'ЯПОНИЯ':
        iconData = Icons.local_florist;
        break;
      case 'ОВОЩНОЙ ЦЕХ':
        iconData = Icons.local_pizza;
        break;
      default:
        iconData = Icons.fastfood;
    }

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Dashboard(cuisine: cuisine),
            ),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color: Colors.orange,
              size: 40.0,
            ),
            const SizedBox(height: 8.0),
            Text(
              cuisine.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ],
        ),
      ),
    );
  }
}
