import 'package:flutter/material.dart';
import 'package:grinlintsa/models/cuisine.dart';
import 'package:grinlintsa/screens/home_page.dart';
import 'package:grinlintsa/screens/dashboard.dart';
import 'package:grinlintsa/services/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper dbHelper = DatabaseHelper();
  await dbHelper.initDatabase(); // Assurez-vous que la base de données est initialisée d'abord
  await dbHelper.initializeCuisines();
  await dbHelper.initializeCategories();
  await dbHelper.initializeSubCategories();
  await dbHelper.initializeTemperatures();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Votre Application',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        hintColor: Colors.orangeAccent,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => FutureBuilder<List<Cuisine>>(
              future: DatabaseHelper().getCuisines(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Erreur: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('Aucune cuisine trouvée.');
                } else {
                  return HomePage(cuisines: snapshot.data!);
                }
              },
            ),
        '/dashboard': (context) {
          final Cuisine cuisine =
              ModalRoute.of(context)?.settings.arguments as Cuisine;
          return Dashboard(cuisine: cuisine);
        },
      },
    );
  }
}
