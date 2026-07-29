import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_edit_event_screen.dart';

class AdminPendingEventsScreen extends StatelessWidget {
  const AdminPendingEventsScreen({
    super.key,
  });

  //--------------------------------------------------
  // EVENT FREIGEBEN
  //--------------------------------------------------
  Future<void> _approveEvent(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection("events")
          .doc(id)
          .set({
        ...data,

        "status": "approved",

        "approvedAt":
            FieldValue.serverTimestamp(),

        "isHighlight":
            data["isHighlight"] ?? false,

        "latitude":
            data["latitude"] ?? 0,

        "longitude":
            data["longitude"] ?? 0,
      });

      await FirebaseFirestore.instance
          .collection("pendingEvents")
          .doc(id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "✅ Event freigegeben",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Fehler: $e",
          ),
        ),
      );
    }
  }

  //--------------------------------------------------
  // EVENT ABLEHNEN
  //--------------------------------------------------
  Future<void> _rejectEvent(
    BuildContext context,
    String id,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection("pendingEvents")
          .doc(id)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "❌ Event abgelehnt",
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "Fehler: $e",
          ),
        ),
      );
    }
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Event-Freigaben"),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore
            .instance
            .collection("pendingEvents")
            .orderBy(
              "createdAt",
              descending: true,
            )
            .snapshots(),

        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final docs =
              snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Keine offenen Events 👍",
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];

              final data =
                  doc.data()
                      as Map<String,
                          dynamic>;

              return Card(
                margin:
                    const EdgeInsets.all(12),

                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        data["name"] ??
                            "Ohne Titel",
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        "Kategorie: ${data["category"] ?? "-"}",
                      ),

                      Text(
                        "Ort: ${data["location"] ?? "-"}",
                      ),

                      Text(
                        "Adresse: ${data["address"] ?? "-"}",
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        data["description"] ??
                            "",
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      if (data["contactName"] !=
                              null &&
                          data["contactName"]
                              .toString()
                              .isNotEmpty)
                        Text(
                          "👤 ${data["contactName"]}",
                        ),

                      if (data["contactMail"] !=
                              null &&
                          data["contactMail"]
                              .toString()
                              .isNotEmpty)
                        Text(
                          "📧 ${data["contactMail"]}",
                        ),

                      if (data["contactPhone"] !=
                              null &&
                          data["contactPhone"]
                              .toString()
                              .isNotEmpty)
                        Text(
                          "📞 ${data["contactPhone"]}",
                        ),

                      const SizedBox(
  height: 16,
),

//--------------------------------------------------
// BUTTONS
//--------------------------------------------------

Column(
  children: [
    //--------------------------------------------------
    // BEARBEITEN
    //--------------------------------------------------
 SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    icon: const Icon(Icons.edit),
    label: const Text(
      "Bearbeiten",
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
    ),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AdminEditEventScreen(
            documentId: doc.id,
            data: data,
          ),
        ),
      );
    },
  ),
),

    //--------------------------------------------------
    // FREIGEBEN + ABLEHNEN
    //--------------------------------------------------
    Row(
      children: [
        Expanded(
          child:
              ElevatedButton.icon(
            icon: const Icon(
              Icons.check,
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.green,
              foregroundColor:
                  Colors.white,
            ),
            onPressed: () =>
                _approveEvent(
              context,
              doc.id,
              data,
            ),
            label: const Text(
              "Freigeben",
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child:
              ElevatedButton.icon(
            icon: const Icon(
              Icons.close,
            ),
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  Colors.red,
              foregroundColor:
                  Colors.white,
            ),
            onPressed: () =>
                _rejectEvent(
              context,
              doc.id,
            ),
            label: const Text(
              "Ablehnen",
            ),
          ),
        ),
      ],
    ),
  ],
)

                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}