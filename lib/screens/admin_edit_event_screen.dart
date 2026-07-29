import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminEditEventScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> data;

  const AdminEditEventScreen({
    super.key,
    required this.documentId,
    required this.data,
  });

  @override
  State<AdminEditEventScreen> createState() =>
      _AdminEditEventScreenState();
}

class _AdminEditEventScreenState
    extends State<AdminEditEventScreen> {
  late TextEditingController name;
  late TextEditingController location;
  late TextEditingController address;
  late TextEditingController description;
  late TextEditingController highlights;
  late TextEditingController instagram;
  late TextEditingController website;
  late TextEditingController contactName;
  late TextEditingController contactMail;
  late TextEditingController contactPhone;
  late TextEditingController flyerUrl;
late TextEditingController latitude;
late TextEditingController longitude;

bool isHighlight = false;


  String category = "stadtfest";

final categories = [
  "stadtfest",
  "schuetzenfest",
  "weihnachtsmarkt",
  "markt",
  "food",
  "festival",
  "konzert",
  "sport",
  "familie",
  "theater",
  "nachtleben",
  "comedy",
  "sonstiges",
];

  DateTime? startDate;
  DateTime? endDate;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    final data = widget.data;

    name =
        TextEditingController(text: data["name"] ?? "");

    location = TextEditingController(
      text: data["location"] ?? "",
    );

    address = TextEditingController(
      text: data["address"] ?? "",
    );

    description = TextEditingController(
      text: data["description"] ?? "",
    );

    highlights = TextEditingController(
      text: data["highlights"] ?? "",
    );

    instagram = TextEditingController(
      text: data["instagram"] ?? "",
    );

    website = TextEditingController(
      text: data["website"] ?? "",
    );

    contactName = TextEditingController(
      text: data["contactName"] ?? "",
    );

    contactMail = TextEditingController(
      text: data["contactMail"] ?? "",
    );

    contactPhone = TextEditingController(
      text: data["contactPhone"] ?? "",
    );

    category =
        data["category"] ?? "stadtfest";

    flyerUrl = TextEditingController(
  text: data["flyerUrl"] ?? "",
);

latitude = TextEditingController(
  text: (data["latitude"] ?? "").toString(),
);

longitude = TextEditingController(
  text: (data["longitude"] ?? "").toString(),
);

isHighlight =
    data["isHighlight"] ?? false;

    if (data["startDate"] is Timestamp) {
      startDate =
          (data["startDate"] as Timestamp)
              .toDate();
    }

    if (data["endDate"] is Timestamp) {
      endDate =
          (data["endDate"] as Timestamp)
              .toDate();
    }
  }

  Future<void> _pickDate(
    bool isStart,
  ) async {
    final picked =
        await showDatePicker(
      context: context,
      initialDate:
          isStart
              ? (startDate ??
                  DateTime.now())
              : (endDate ??
                  DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        startDate = picked;
      } else {
        endDate = picked;
      }
    });
  }

  Future<void> _save() async {
    setState(() {
      isSaving = true;
    });

    await FirebaseFirestore.instance
        .collection("events")
        .doc(widget.documentId)
        .update({
      "name": name.text.trim(),
      "location": location.text.trim(),
      "address": address.text.trim(),
      "description":
          description.text.trim(),
      "highlights":
          highlights.text.trim(),
      "instagram":
          instagram.text.trim(),
      "website":
          website.text.trim(),
      "contactName":
          contactName.text.trim(),
      "contactMail":
          contactMail.text.trim(),
      "contactPhone":
          contactPhone.text.trim(),
      "category": category,
      "flyerUrl": flyerUrl.text.trim(),

"latitude":
    double.tryParse(latitude.text) ?? 0,

"longitude":
    double.tryParse(longitude.text) ?? 0,

"isHighlight": isHighlight,

      if (startDate != null)
        "startDate":
            Timestamp.fromDate(
          startDate!,
        ),

      if (endDate != null)
        "endDate":
            Timestamp.fromDate(
          endDate!,
        ),
    });

    if (!mounted) return;

    Navigator.pop(context);
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border:
              const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Event bearbeiten"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field(
            label: "Eventname",
            controller: name,
          ),

          _field(
            label: "Ort",
            controller: location,
          ),

          _field(
            label: "Adresse",
            controller: address,
          ),

          DropdownButtonFormField<String>(
            value: category,
            decoration:
                const InputDecoration(
              labelText: "Kategorie",
              border:
                  OutlineInputBorder(),
            ),
            items: categories.map((c) {
              return DropdownMenuItem(
                value: c,
                child: Text(c),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                category = value;
              });
            },
          ),

          const SizedBox(height: 12),

          _field(
            label: "Beschreibung",
            controller: description,
            lines: 4,
          ),

          _field(
            label: "Highlights",
            controller: highlights,
            lines: 2,
          ),

          _field(
            label: "Instagram",
            controller: instagram,
          ),

          _field(
            label: "Website",
            controller: website,
          ),

_field(
  label: "Flyer URL",
  controller: flyerUrl,
),

_field(
  label: "Latitude",
  controller: latitude,
),

_field(
  label: "Longitude",
  controller: longitude,
),

          const SizedBox(height: 20),

          _field(
            label: "Kontaktperson",
            controller: contactName,
          ),

          _field(
            label: "E-Mail",
            controller: contactMail,
          ),

          _field(
            label: "Telefon",
            controller: contactPhone,
          ),

      SwitchListTile(
  title: const Text(
    "⭐ Highlight",
  ),
  value: isHighlight,
  onChanged: (value) {
    setState(() {
      isHighlight = value;
    });
  },
),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _pickDate(true),
                  child: Text(
                    startDate == null
                        ? "Startdatum"
                        : "${startDate!.day}.${startDate!.month}.${startDate!.year}",
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _pickDate(false),
                  child: Text(
                    endDate == null
                        ? "Enddatum"
                        : "${endDate!.day}.${endDate!.month}.${endDate!.year}",
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: Text(
              isSaving
                  ? "Speichern..."
                  : "Änderungen speichern",
            ),
            onPressed:
                isSaving ? null : _save,
          ),
        ],
      ),
    );
  }

  @override
void dispose() {
  name.dispose();
  location.dispose();
  address.dispose();
  description.dispose();
  highlights.dispose();
  instagram.dispose();
  website.dispose();
  flyerUrl.dispose();
  latitude.dispose();
  longitude.dispose();
  contactName.dispose();
  contactMail.dispose();
  contactPhone.dispose();

  super.dispose();
}
}