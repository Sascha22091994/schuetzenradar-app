import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationAdminScreen extends StatelessWidget {
  const LocationAdminScreen({super.key});

  //--------------------------------------------------
  // ADD / EDIT DIALOG
  //--------------------------------------------------
  void _showDialog(BuildContext context, [DocumentSnapshot? doc]) {
    final name = TextEditingController(
        text: doc != null ? doc['name'] : '');
    final instagram = TextEditingController(
        text: doc != null ? doc['instagram'] : '');
    final website = TextEditingController(
        text: doc != null ? doc['website'] : '');

    bool hasAdler = doc != null ? doc['hasAdler'] : false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(doc == null ? "Ort hinzufügen" : "Bearbeiten"),
          content: SingleChildScrollView(
            child: Column(
              children: [

                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: "Name"),
                ),

                TextField(
                  controller: instagram,
                  decoration:
                      const InputDecoration(labelText: "Instagram"),
                ),

                TextField(
                  controller: website,
                  decoration:
                      const InputDecoration(labelText: "Website"),
                ),

                SwitchListTile(
                  title: const Text("Adlerschießen aktiv"),
                  value: hasAdler,
                  onChanged: (v) => setState(() => hasAdler = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {

                final id = name.text.toLowerCase().replaceAll(' ', '_');

                if (doc == null) {
                  //----------------------------------
                  // CREATE
                  //----------------------------------
                  await FirebaseFirestore.instance
                      .collection('locations')
                      .doc(id)
                      .set({
                    "name": name.text,
                    "instagram": instagram.text,
                    "website": website.text,
                    "hasAdler": hasAdler,
                  });
                } else {
                  //----------------------------------
                  // UPDATE
                  //----------------------------------
                  await FirebaseFirestore.instance
                      .collection('locations')
                      .doc(doc.id)
                      .update({
                    "name": name.text,
                    "instagram": instagram.text,
                    "website": website.text,
                    "hasAdler": hasAdler,
                  });
                }

                Navigator.pop(context);
              },
              child: const Text("Speichern"),
            ),
          ],
        ),
      ),
    );
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Orte verwalten")),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(context),
        child: const Icon(Icons.add),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('locations')
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView(
            children: docs.map((doc) {
              return Dismissible(
                key: Key(doc.id),

                //----------------------------------
                // DELETE
                //----------------------------------
                onDismissed: (_) async {
                  await FirebaseFirestore.instance
                      .collection('locations')
                      .doc(doc.id)
                      .delete();
                },

                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),

                child: ListTile(
                  title: Text(doc['name']),
                  subtitle: Text(
                      "Instagram: ${doc['instagram']}\nWebsite: ${doc['website']}"),

                  //----------------------------------
                  // EDIT
                  //----------------------------------
                  onTap: () => _showDialog(context, doc),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
