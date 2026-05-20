import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubmitNewsScreen extends StatefulWidget {
  const SubmitNewsScreen({super.key});

  @override
  State<SubmitNewsScreen> createState() => _SubmitNewsScreenState();
}

class _SubmitNewsScreenState extends State<SubmitNewsScreen> {

  final title = TextEditingController();
  final content = TextEditingController();
  final location = TextEditingController();

  bool _isLoading = false;

  //--------------------------------------------------
  Future<void> _submit() async {
    if (title.text.isEmpty ||
        content.text.isEmpty ||
        location.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bitte alle Felder ausfüllen")),
      );
      return;
    }

    setState(() => _isLoading = true);

    await FirebaseFirestore.instance.collection('submissions').add({
      "type": "news",
      "status": "pending",
      "title": title.text,
      "content": content.text,
      "location": location.text,
      "createdAt": FieldValue.serverTimestamp(),
    });

    setState(() => _isLoading = false);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ News wird geprüft")),
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
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("News melden 📰"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          //--------------------------------------------------
          // ✅ HEADER
          //--------------------------------------------------
          const Text(
            "Neue Meldung erstellen",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Teile wichtige Infos, Ereignisse oder Highlights rund ums Fest.",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // ✅ EINGABE
          //--------------------------------------------------
          _niceField(
            controller: title,
            label: "Titel",
            icon: Icons.title,
          ),

          _niceField(
            controller: location,
            label: "Ort",
            icon: Icons.location_on,
          ),

          _niceField(
            controller: content,
            label: "Nachricht / Inhalt",
            maxLines: 4,
            icon: Icons.notes,
          ),

          const SizedBox(height: 30),

          //--------------------------------------------------
          // ✅ BUTTON
          //--------------------------------------------------
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    "News einreichen 🚀",
                    style: TextStyle(fontSize: 16),
                  ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}