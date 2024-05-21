import 'package:flutter/material.dart';
import 'package:grinlintsa/models/cuisine.dart';
import 'package:grinlintsa/screens/list_cooks.dart';
import 'package:grinlintsa/screens/manage_cooks.dart';

class Dashboard extends StatelessWidget {
  final Cuisine cuisine;

  const Dashboard({Key? key, required this.cuisine}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String imagePath;

    switch (cuisine.name) {
      case 'ШАУРМА':
        imagePath =
            'assets/bg-shawarma.jpg'; // Remplacez 'assets/shawarma_icon.png' par le chemin de votre image pour la shawarma
        break;
      case 'ПИЦЦА':
        imagePath =
            'assets/bg-pizza.jpg'; // Remplacez 'assets/pizza_icon.png' par le chemin de votre image pour la pizza
        break;
      case 'ЯПОНИЯ':
        imagePath =
            'assets/bg-sushi.jpg'; // Remplacez 'assets/sushi_icon.png' par le chemin de votre image pour le sushi
        break;
      case 'ОВОЩНОЙ ЦЕХ':
        imagePath =
            'assets/bg-legumes.jpg'; // Remplacez 'assets/vegetable_icon.png' par le chemin de votre image pour le département de légumes
        break;
      default:
        imagePath =
            'assets/default_icon.png'; // Remplacez 'assets/default_icon.png' par le chemin de votre image par défaut
    }

    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails details) {
        if (details.primaryVelocity! > 0) {
          // Glissement vers la droite, effectuer l'action de retour en arrière
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading:
              false, // Cela désactive le bouton de retour automatique
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
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    Text(
                      cuisine.name,
                      style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ListCooks(cuisine: cuisine),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFEA3423), // Couleur de fond du bouton
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.print,
                                  color: Color(0xFFFBE14F), size: 70),
                              SizedBox(width: 10),
                              Text(
                                'Управление маркировкой',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ManageCooks(cuisine: cuisine),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA3423), // Couleur de fond du bouton
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: Color(0xFFFBE14F), // Couleur de l'icône
                                size: 70,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Управление кухней',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // Couleur du texte
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
