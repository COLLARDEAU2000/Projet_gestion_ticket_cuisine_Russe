// ignore_for_file: file_names, unrelated_type_equality_checks
import 'package:flutter/foundation.dart'; 
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterManager {
  // Vérifie si le Bluetooth est activé
  static Future<bool> checkBluetooth() async {
    try {
      final bool result = await PrintBluetoothThermal.bluetoothEnabled;
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la vérification du Bluetooth : $e');
      }
      return false;
    }
  }

  // veification de la connection a une imprimante et recupere les informations de l'imprimante
  // Vérifie la connexion à une imprimante
  static Future<List<BluetoothInfo>> checkConnectionPrinter() async {
    try {
      final List<BluetoothInfo> listResult =
          await PrintBluetoothThermal.pairedBluetooths;
      await Future.forEach(listResult, (BluetoothInfo bluetooth) {
        String name = bluetooth.name;
        String mac = bluetooth.macAdress;
      });
      return listResult;
    } catch (e) {
      if (kDebugMode) {
        print(
            'Erreur lors de la vérification de la connexion à l\'imprimante : $e');
      }
      return [];
    }
  }

  // Vérifie l'état de connexion de l'imprimante et lance l'impression
  static Future<bool> impression(
      List<BluetoothInfo> bluetooth, List<dynamic> infosTickets) async {
    bool flag = false;
    try {
      final bool result = await PrintBluetoothThermal.connect(
          macPrinterAddress: bluetooth.first.macAdress);
      final bool connectionStatus =
          await PrintBluetoothThermal.connectionStatus;
      if (connectionStatus && result) {
        createTicket(infosTickets);
        flag = true;
      }
    } catch (e) {
      print('Erreur lors de l\'impression : $e');
    }
    return flag;
  }

  // Envoie des informations a imprimer a l'imprimante
  static Future<void> createTicket(List<dynamic> infosTickets) async {
    String cookName = "";
    String produitName = "";
    String DateOne = "";
    String DateTwo = "";
    String DateThree = "";

    try {
      if (infosTickets.length == 6) {
        while (infosTickets[2] > 0) {
          String enter = '\n';
          cookName = infosTickets[0] + enter; // indice cuinier
          produitName = infosTickets[1] + enter; // indice produit
          DateOne = infosTickets[3] + enter; // indice date 1
          DateTwo = infosTickets[4] + enter; // indice date 2
          DateThree = infosTickets[5] + enter; // indice date 3
          await PrintBluetoothThermal.writeBytes(enter.codeUnits);
          //size of 1-5
          String text = "Infromations Ticket $enter";
          await PrintBluetoothThermal.writeString(
              printText: PrintTextSize(size: 4, text: text));
          await PrintBluetoothThermal.writeString(
              printText:
                  PrintTextSize(size: 3, text: "Produits : $produitName"));
          await PrintBluetoothThermal.writeString(
              printText: PrintTextSize(size: 3, text: DateOne));
          await PrintBluetoothThermal.writeString(
              printText: PrintTextSize(size: 3, text: DateTwo));
          await PrintBluetoothThermal.writeString(
              printText: PrintTextSize(size: 3, text: DateThree));
          infosTickets[2]--;
        }
      } else {
        while (infosTickets[2] > 0) {
          String enter = '\n';
          cookName = infosTickets[0] + enter; // indice cuinier
          produitName = infosTickets[1] + enter; // indice produit
          DateOne = infosTickets[3] + enter; // indice date 1
          DateTwo = infosTickets[4] + enter; // indice date 2
          DateThree = infosTickets[5] + enter; // indice date 3
          await PrintBluetoothThermal.writeBytes(enter.codeUnits);
          //size of 1-5
          String text = "Infromations Ticket $enter";
          await PrintBluetoothThermal.writeString(
              printText: PrintTextSize(size: 4, text: text));
          await PrintBluetoothThermal.writeString(
              printText:
                  PrintTextSize(size: 3, text: "Produits : $produitName"));
          await PrintBluetoothThermal.writeString(
              printText: PrintTextSize(size: 3, text: DateOne));
          await PrintBluetoothThermal.writeString(
              printText: PrintTextSize(size: 3, text: DateTwo));
          infosTickets[2]--;
        }
      }
    } catch (e) {
      print('Erreur lors de la création du ticket : $e');
    }
  }
}
