// Classe pour gérer les opérations liées aux tickets
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/foundation.dart';

class TicketManager {
  // Instance de BlueThermalPrinter pour interagir avec l'imprimante thermique Bluetooth
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
// Méthode pour vérifier si le Bluetooth est activé
  Future<bool?> isBluetoothActive() async {
    
    return await _bluetooth.isOn;
  }

  // Méthode pour récupérer l'imprimante connectée
  Future<BluetoothDevice?> getConnectedPrinter() async {
    // Vérifie si le Bluetooth est disponible
    bool? isConnected = await _bluetooth.isOn;
    if (isConnected == true) {
      // Récupère la liste des périphériques appairés
      List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      // Renvoie le premier périphérique de la liste
      return devices.first;
    } else {
      // Retourne null si aucun périphérique n'est connecté
      return null;
    }
  }

  // Méthode pour imprimer un ticket avec des informations spécifiques
  Future<void> printTicket(List<dynamic> infoTickets) async {
    // Récupère l'imprimante connectée
    BluetoothDevice? printer = await getConnectedPrinter();
    // Tente de se connecter à l'imprimante
    bool connected = connect(printer);
    if (printer != null && connected) {
      String cookName = "";
      String produitName = "";
      String DateOne = "";
      String DateTwo = "";
      String DateThree = "";

      try {
        if (infoTickets.length == 6) {
          while (infoTickets[2] > 0) {
            cookName = infoTickets[0]; // indice cuinier
            produitName = infoTickets[1]; // indice produit
            DateOne = infoTickets[3]; // indice date 1
            DateTwo = infoTickets[4]; // indice date 2
            DateThree = infoTickets[5]; // indice date 3

            // Imprime les informations du ticket

            _bluetooth.printNewLine();
            _bluetooth.printCustom("Informations tickets :  ", 3, 1);

            _bluetooth.printNewLine();
            _bluetooth.printCustom("cusinier : $cookName", 2, 1);

            _bluetooth.printNewLine();
            _bluetooth.printCustom("Produit : $produitName ", 2, 1);

            _bluetooth.printNewLine();
            _bluetooth.printCustom("Date 1 : $DateOne ", 2, 1);

            _bluetooth.printNewLine();
            _bluetooth.printCustom("Date 2 : $DateTwo", 2, 1);

            _bluetooth.printNewLine();
            _bluetooth.printCustom("Date 3 : $DateThree", 2, 1);

            _bluetooth.paperCut(); // Coupe le papier

            infoTickets[2]--;
          }
        } else {
          while (infoTickets[2] > 0) {
            String enter = '\n';
            cookName = infoTickets[0] + enter; // indice cuinier
            produitName = infoTickets[1] + enter; // indice produit
            DateOne = infoTickets[3] + enter; // indice date 1
            DateTwo = infoTickets[4] + enter; // indice date 2

            // Imprime les informations du ticket
            _bluetooth.printNewLine();
            _bluetooth.printCustom("Informations tickets :  ", 3, 1);

            _bluetooth.printNewLine();
            _bluetooth.printCustom("cusinier : $cookName", 2, 1);

            _bluetooth.printNewLine();
            _bluetooth.printCustom("Produit : $produitName ", 2, 1);

            _bluetooth.printNewLine();
            _bluetooth.printCustom("Date 1 : $DateOne ", 2, 1);

            _bluetooth.printNewLine();
            _bluetooth.printCustom("Date 2 : $DateTwo", 2, 1);

            _bluetooth.paperCut(); // Coupe le papier

            infoTickets[2]--;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Erreur lors de la création du ticket : $e');
        }
      }
    } else {
      // Lance une exception si aucune imprimante n'est connectée
      throw Exception('Aucune imprimante Bluetooth n\'est connectée.');
    }
  }

  // Méthode pour se connecter à l'imprimante
  bool connect(BluetoothDevice? device) {
    bool completer =
        false; // Variable pour indiquer si la connexion est réussie

    if (device != null) {
      _bluetooth.connect(device);
      completer = true;
    } else {
      // Affiche un message si aucun périphérique n'est sélectionné
      if (kDebugMode) {
        print('Pas de connection a une imprimante .');
      }
      completer = false; // Aucun périphérique sélectionné
    }

    return completer; // Retourne l'état de la connexion
  }

  // Autres méthodes de gestion des tickets...
}
