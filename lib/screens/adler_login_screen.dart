import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/email_service.dart';
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
  void _requestAccess() {
    EmailService.sendFeedback(
      subject: "Zugang Adlerschießen – ${widget.locationName}",
      body:
          "Hallo,\n\n"
          "ich möchte Zugang für das Adlerschießen erhalten.\n\n"
          "📍 Ort / Fest:\n"
          "${widget.locationName}\n\n"
          "Name / Funktion vor Ort:\n\n"
          "Vielen Dank!",
    );
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Login - ${widget.locationName}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [

              const SizedBox(height: 20),

              Text(
                "Zugriff nur für Berechtigte",
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
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

              const SizedBox(height: 25),

              //--------------------------------------------------
              // ✅ INFO BLOCK (FIXED)
              //--------------------------------------------------
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E)
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      "🦅 Adlerschießen – Live Bereich",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Hier können Schützen während des Adlerschießens live erfasst werden.\n\n"
                      "👉 Teilnehmer eintragen\n"
                      "👉 Schüsse zählen\n"
                      "👉 Stand in Echtzeit verfolgen\n\n"
                      "Der Zugang ist nur für berechtigte Schreiber vor Ort möglich.",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              //--------------------------------------------------
              // BUTTON
              //--------------------------------------------------
              ElevatedButton.icon(
                onPressed: _requestAccess,
                icon: const Icon(Icons.mail_outline),
                label: const Text("Zugang anfragen"),
              ),

              const SizedBox(height: 10),

              //--------------------------------------------------
              // HINWEIS
              //--------------------------------------------------
              Text(
                "👉 Du bist Besucher? Dann nutze den Live-Bereich zur Ansicht.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
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