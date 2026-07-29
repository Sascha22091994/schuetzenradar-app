import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class SubmitEventScreen extends StatefulWidget {
  const SubmitEventScreen({super.key});

  @override
  State<SubmitEventScreen> createState() =>
      _SubmitEventScreenState();
}

class _SubmitEventScreenState extends State<SubmitEventScreen> {

  final name = TextEditingController();
  final location = TextEditingController();
  final address = TextEditingController();
  final description = TextEditingController();
  final highlights = TextEditingController();
  final instagram = TextEditingController();
  final website = TextEditingController();
  final contactName = TextEditingController();
final contactMail = TextEditingController();
final contactPhone = TextEditingController();

String selectedCategory = "stadtfest";

final categories = [
  "stadtfest",
  "schuetzenfest",
  "weihnachtsmarkt",
  "markt",
  "food",
  "festival",
  "Konzert",
  "Sport",
  "Familie",
  "Sonstiges",
];

  File? _selectedImage;


  DateTime? startDate;
  DateTime? endDate;

  bool _isLoading = false;

  //--------------------------------------------------
  // ✅ DEUTSCHER DATE PICKER
  //--------------------------------------------------
  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('de', 'DE'),
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),

      // ✅ Design passend zur App
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
            ),
          ),
          child: child!,
        );
      },
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

  //--------------------------------------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  //--------------------------------------------------
  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("Event_uploads")
          .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

      await ref.putFile(_selectedImage!);

      return await ref.getDownloadURL();

    } catch (e) {
      debugPrint("Upload Fehler: $e");
      return null;
    }
  }

  //--------------------------------------------------
  Future<void> _submit() async {
  if (name.text.isEmpty ||
      location.text.isEmpty ||
      address.text.isEmpty ||
      startDate == null ||
      endDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Bitte alle Pflichtfelder ausfüllen",
        ),
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  final flyerUrl = await _uploadImage();

  await FirebaseFirestore.instance
      .collection('pendingEvents')
      .add({
    "type": "Event",

    "status": "pending",

    "source": "user",

    "name": name.text.trim(),

    "category": selectedCategory,

    "location": location.text.trim(),

    "address": address.text.trim(),

    "description": description.text.trim(),

    "highlights": highlights.text.trim(),

    "instagram": instagram.text.trim(),

    "website": website.text.trim(),

    "contactName": contactName.text.trim(),

    "contactMail": contactMail.text.trim(),

    "contactPhone": contactPhone.text.trim(),


    "startDate":
        Timestamp.fromDate(startDate!),

    "endDate":
        Timestamp.fromDate(endDate!),

    "flyerUrl": flyerUrl,

    "createdAt":
        FieldValue.serverTimestamp(),
  });

  if (!mounted) return;

  setState(() => _isLoading = false);

  Navigator.pop(context);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "✅ Vielen Dank! Dein Event wird geprüft.",
      ),
    ),
  );
}

  //--------------------------------------------------
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  //--------------------------------------------------
  Widget _niceField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon) : null,
          labelText: label,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  //--------------------------------------------------
  // ✅ DATUM FORMAT
  //--------------------------------------------------
  String _formatDate(DateTime? date) {
    if (date == null) return "";
    return DateFormat("dd.MM.yyyy", "de_DE").format(date);
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text(
    "Event einreichen 🎉",
  ),
),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text(
            "Neues Event einreichen",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          _niceField(
            controller: name,
            label: "Eventname",
            icon: Icons.event,
          ),

          _niceField(
            controller: location,
            label: "Ort",
            icon: Icons.location_city,
          ),

          _niceField(
            controller: address,
            label: "Adresse",
            icon: Icons.place,
          ),

_sectionTitle("Kategorie"),

DropdownButtonFormField<String>(
  value: selectedCategory,
  decoration: InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
  items: categories.map((category) {
    return DropdownMenuItem(
      value: category,
      child: Text(category),
    );
  }).toList(),
  onChanged: (value) {
    if (value == null) return;

    setState(() {
      selectedCategory = value;
    });
  },
),

const SizedBox(height: 12),

          _sectionTitle("Details"),

          _niceField(
            controller: description,
            label: "Beschreibung",
            maxLines: 2,
            icon: Icons.notes,
          ),

          _niceField(
            controller: highlights,
            label: "Highlights",
            icon: Icons.star,
          ),

          _sectionTitle("Links"),

_niceField(
  controller: instagram,
  label: "Instagram Profil",
  icon: Icons.camera_alt,
),

_niceField(
  controller: website,
  label: "Website",
  icon: Icons.language,
),

_sectionTitle("Kontakt"),

_niceField(
  controller: contactName,
  label: "Ansprechpartner",
  icon: Icons.person,
),

_niceField(
  controller: contactMail,
  label: "E-Mail",
  icon: Icons.email,
),

_niceField(
  controller: contactPhone,
  label: "Telefon (optional)",
  icon: Icons.phone,
),

          _niceField(
            controller: instagram,
            label: "Instagram",
            icon: Icons.camera_alt,
          ),

          _niceField(
            controller: website,
            label: "Website",
            icon: Icons.language,
          ),

          _sectionTitle("Extras"),

      
          //------------------------------------------
          // ✅ ZEITRAUM MIT DEUTSCHER FORMATIERUNG
          //------------------------------------------
          _sectionTitle("Zeitraum"),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickDate(true),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    startDate == null
                        ? "Start"
                        : _formatDate(startDate),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickDate(false),
                  icon: const Icon(Icons.event),
                  label: Text(
                    endDate == null
                        ? "Ende"
                        : _formatDate(endDate),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          //------------------------------------------
          // 📎 IMAGE PICKER
          //------------------------------------------
          _sectionTitle("Flyer / Bild"),

          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload),
                          SizedBox(height: 6),
                          Text("Bild auswählen"),
                        ],
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          //------------------------------------------
          // ✅ SUBMIT BUTTON
          //------------------------------------------
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const Column(
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 8),
                      Text("Wird hochgeladen..."),
                    ],
                  )
                : const Text(
                    "Event einreichen 🚀",
                    style: TextStyle(fontSize: 16),
                  ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}