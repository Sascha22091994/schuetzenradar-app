import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'adler_screen.dart';

class AdlerLoginScreen extends StatefulWidget {
  final String locationId;
  final String locationName;

  const AdlerLoginScreen({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  @override
  State<AdlerLoginScreen> createState() => _AdlerLoginScreenState();
}

class _AdlerLoginScreenState extends State<AdlerLoginScreen> {

  final TextEditingController passwordController = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    setState(() => loading = true);

    final doc = await FirebaseFirestore.instance
        .collection('location_admins')
        .doc(widget.locationId)
        .get();

    if (!doc.exists) {
      showError("Kein Zugriff konfiguriert");
      setState(() => loading = false);
      return;
    }

    final data = doc.data()!;

    if (passwordController.text == data['password']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdlerScreen(
            locationId: widget.locationId,
            locationName: widget.locationName,
          ),
        ),
      );
    } else {
      showError("Falsches Passwort");
    }

    setState(() => loading = false);
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login - ${widget.locationName}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const SizedBox(height: 20),

            const Text(
              "Zugriff nur für Berechtigte",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Passwort",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : _login,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Login"),
            ),
          ],
        ),
      ),
    );
  }

  //--------------------------------------------------
  void showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
