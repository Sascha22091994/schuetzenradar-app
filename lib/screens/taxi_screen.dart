import 'package:flutter/material.dart';

class TaxiScreen extends StatelessWidget {
  const TaxiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taxis = [
  ["Alt Espelkamp, Rahden", "Taxi Blanke", "05771 2107"],
  ["Alt Espelkamp, Kleindorf", "Taxi Urban", "05772 3000"],
  ["Rahden, Preußisch Ströhen, Sielhorst, Steinbrink, Stelle, Tonnenheide, Varl, Wehe", "Taxi Urban", "05771 844"],
  ["Rahden", "Wolfgang Kassen Taxi", "05771 1060"],
  ["Lavelsloh", "Taxi Osterkamp", "05763 2526"],
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Taxis im Kreis")),

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: taxis.map((t) {

          return Card(
            child: ListTile(
              leading: const Icon(Icons.local_taxi),
              title: Text(t[1]),
              subtitle: Text("${t[0]} \nTel: ${t[2]}"),
              isThreeLine: true,
            ),
          );

        }).toList(),
      ),
    );
  }
}