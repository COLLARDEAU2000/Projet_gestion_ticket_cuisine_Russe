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
        title: const Text(
          'кухонные списки',
          style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold), // Taille de la police
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: Image.asset(
          'assets/logorussie.png',
          width: 40,
          height: 40,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/background.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: OrientationBuilder(
          builder: (context, orientation) {
            return _buildGrid(orientation, context);
          },
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
          return Center(
            child: GridView.builder(
              gridDelegate: _buildGridDelegate(orientation),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return _buildCuisineCard(snapshot.data![index], context);
              },
            ),
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
    String imagePath;

    switch (cuisine.name) {
      case 'ШАУРМА':
        imagePath = 'assets/icon-shawarma.png'; // Remplacez 'assets/shawarma_icon.png' par le chemin de votre image pour la shawarma
        break;
      case 'ПИЦЦА':
        imagePath = 'assets/icon-pizza.png'; // Remplacez 'assets/pizza_icon.png' par le chemin de votre image pour la pizza
        break;
      case 'ЯПОНИЯ':
        imagePath = 'assets/icon-sushi.png'; // Remplacez 'assets/sushi_icon.png' par le chemin de votre image pour le sushi
        break;
      case 'ОВОЩНОЙ ЦЕХ':
        imagePath = 'assets/icon-legumes.png'; // Remplacez 'assets/vegetable_icon.png' par le chemin de votre image pour le département de légumes
        break;
      default:
        imagePath = 'assets/default_icon.png'; // Remplacez 'assets/default_icon.png' par le chemin de votre image par défaut
    }

    return Card(
      color: const Color(0xFFEA3423),
      child: Center(
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
              Image.asset(
                imagePath,
                width: 60, // Largeur de l'image
                height: 60, // Hauteur de l'image
              ),
              const SizedBox(height: 8.0),
              Text(
                cuisine.name,
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
