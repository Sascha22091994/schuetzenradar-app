import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Taxi {
  final String id;
  final String name;
  final List<String> areas;
  final String phone;

  Taxi({
    required this.id,
    required this.name,
    required this.areas,
    required this.phone,
  });

  factory Taxi.fromMap(String id, Map<String, dynamic> map) {
    return Taxi(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      areas: List<String>.from(map['areas'] ?? []),
    );
  }
}

class TaxiScreen extends StatelessWidget {
  const TaxiScreen({super.key});

  //--------------------------------------------------
  // ✅ PREMIUM CALL DIALOG
  //--------------------------------------------------
Future<void> _confirmCall(BuildContext context, Taxi taxi) async {
  final cleaned = taxi.phone.replaceAll(" ", "");
  final uri = Uri.parse("tel:$cleaned");

  showDialog(
    context: context,
    builder: (_) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Dialog(
        backgroundColor: isDark
            ? Colors.grey.shade900
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Icon(Icons.local_taxi, size: 40, color: Colors.amber),

              const SizedBox(height: 12),

              Text(
                taxi.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                taxi.phone,
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 16),

              const Text("Möchtest du dieses Taxi anrufen?"),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Abbrechen"),
                  ),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    icon: const Icon(Icons.phone),
                    label: const Text("Anrufen"),
                    onPressed: () async {
                      Navigator.pop(context);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }, // ✅ WICHTIG: builder schließen
  );
}
  //--------------------------------------------------
  // ✅ ALLE ORTE ANZEIGEN
  //--------------------------------------------------
  
void _showAllAreas(BuildContext context, Taxi taxi) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      final isDark = Theme.of(context).brightness == Brightness.dark;

      return Container(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Text(
                "${taxi.name} – Gebiet",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: taxi.areas.map((area) {
                  return Chip(
                    label: Text(area),
                    backgroundColor: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              TextButton(
                child: const Text("Schließen"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    },
  );
}
  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🚕 Taxis in deiner Nähe"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('taxis').snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final taxis = snapshot.data!.docs.map((doc) {
            return Taxi.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          //--------------------------------------------------
          // ✅ SORTIERUNG (PREMIUM!)
          //--------------------------------------------------
          taxis.sort((a, b) {
            final aData = snapshot.data!.docs
                .firstWhere((d) => d.id == a.id)
                .data() as Map<String, dynamic>;
            final bData = snapshot.data!.docs
                .firstWhere((d) => d.id == b.id)
                .data() as Map<String, dynamic>;

            return (aData['priority'] ?? 99)
                .compareTo(bData['priority'] ?? 99);
          });

   return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: taxis.length + 1,
            itemBuilder: (context, index) {
              //--------------------------------------------------
              // ✅ INFO BOX (LETZTES ELEMENT)
              //--------------------------------------------------
              if (index == taxis.length) {
                final isDark =
                    Theme.of(context).brightness == Brightness.dark;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20, horizontal: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(height: 8),
                        Text(
                          "Fehlt dein Taxiunternehmen oder bist du Veranstalter und möchtest hier gelistet werden?",
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Dann nimm gerne Kontakt mit mir auf 😊",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              //--------------------------------------------------
              // ✅ NORMALER TAXI EINTRAG
              //--------------------------------------------------
              final taxi = taxis[index];
              final visibleAreas = taxi.areas.take(3).toList();
              final extraCount =
                  taxi.areas.length - visibleAreas.length;

              final isDark =
                  Theme.of(context).brightness == Brightness.dark;

              return Card(
                color: isDark
                    ? Colors.grey.shade900
                    : Colors.white,
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _confirmCall(context, taxi),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.local_taxi,
                            color: Colors.amber, size: 28),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                taxi.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),

                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  ...visibleAreas.map((area) =>
                                      Chip(
                                        label: Text(area),
                                        backgroundColor: isDark
                                            ? Colors
                                                .grey.shade800
                                            : Colors
                                                .grey.shade200,
                                        labelStyle:
                                            const TextStyle(
                                                fontSize: 12),
                                      )),
                                  if (extraCount > 0)
                                    GestureDetector(
                                      onTap: () =>
                                          _showAllAreas(
                                              context, taxi),
                                      child: Text(
                                        "+ $extraCount weitere",
                                        style:
                                            const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              Text(
                                "📞 ${taxi.phone}",
                                style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        InkWell(
                          onTap: () =>
                              _confirmCall(context, taxi),
                          borderRadius:
                              BorderRadius.circular(20),
                          child: Container(
                            padding:
                                const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.green.shade800
                                  : Colors.green.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.phone,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  //--------------------------------------------------
void showError(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));
}

}
