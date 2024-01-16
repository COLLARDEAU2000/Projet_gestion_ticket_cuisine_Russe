// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:grinlintsa/models/cuisine.dart';
import 'package:grinlintsa/screens/list_cooks.dart';
import 'package:grinlintsa/screens/manage_cooks.dart';

class Dashboard extends StatelessWidget {
  final Cuisine cuisine;

  const Dashboard({Key? key, required this.cuisine}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cuisine.name),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                cuisine.name,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  // dashboard.dart

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListCooks(cuisine: cuisine),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.print),
                      SizedBox(width: 10),
                      Text(
                        'Gestion des Tickets',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                    ],
                  ),
                ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageCooks(cuisine: cuisine),
                        ),
                      );
                    },
                    // ... Autres styles de bouton
                    child: const Row(
                      children: [
                        Icon(Icons.person), // Ajoutez l'icône bonhomme ici
                        SizedBox(width: 10),
                        Text('Gestion des Cuisiniers',style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
