import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/email_service.dart';
import 'adler_screen.dart';
import 'adler_live_screen.dart';

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

  Future<void> _openLiveSelection() async {
  final locationsSnapshot =
      await FirebaseFirestore.instance.collection('locations').get();

  final futures = locationsSnapshot.docs.map((doc) async {
    final jung = await FirebaseFirestore.instance
        .collection('adler_events')
        .doc(doc.id)
        .collection('events')
        .doc('jung')
        .get();

    final alt = await FirebaseFirestore.instance
        .collection('adler_events')
        .doc(doc.id)
        .collection('events')
        .doc('alt')
        .get();

    final isLive = (jung.data()?['isActive'] == true) ||
        (alt.data()?['isActive'] == true);

    return MapEntry(doc, isLive);
  });

  final results = await Future.wait(futures);

  final sorted = [
    ...results.where((e) => e.value),
    ...results.where((e) => !e.value),
  ];

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Ort auswählen"),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          children: sorted.map((entry) {
            final doc = entry.key;
            final isLive = entry.value;

            return ListTile(
              title: Text(doc['name'] ?? ""),
              subtitle: Text(
                isLive ? "🔥 Live aktiv" : "Keine aktuellen Daten",
              ),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdlerLiveScreen(
                      locationId: doc.id,
                      locationName: doc['name'] ?? "",
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    ),
  );
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
  elevation: 0,
  backgroundColor: Colors.green.shade700,

  flexibleSpace: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.green.shade800,
          Colors.green.shade600,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),

  title: Row(
    children: [
      const Icon(Icons.lock_outline, color: Colors.white, size: 35),
      const SizedBox(width: 8),

      Expanded(
        child: Text(
          "Login – ${widget.locationName}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            letterSpacing: 0.4,
          ),
        ),
      ),
    ],
  ),

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
// 👀 ZUSCHAUER INFO (NEU)
//--------------------------------------------------
Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: Colors.blue.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Colors.blue.withValues(alpha: 0.4),
      width: 1,
    ),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.center, // ✅ geändert!
    children: [

      Row(
        mainAxisAlignment: MainAxisAlignment.center, // ✅ Zentriert Icon + Titel
        children: const [
          Icon(Icons.visibility, color: Colors.blue),
          SizedBox(width: 6),
          Text(
            "Zuschauer?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),

      const SizedBox(height: 8),

      const Text(
        "👉 Du willst das Adlerschießen nur verfolgen?\n\n"
        "Kein Login nötig!\n\n"
        "➡️ Tippe unten in der Navigationsleiste auf den „Live“ Button und sieh dir alle aktuell laufenden Adlerschießen an.",
        textAlign: TextAlign.center, // ✅ GANZ WICHTIG!
      ),
    ],
  ),
),

const SizedBox(height: 12),

//--------------------------------------------------
// 🔴 LIVE CALL TO ACTION
//--------------------------------------------------
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.red.shade400,
        Colors.red.shade600,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  ),

  child: Column(
    children: [

      //--------------------------------------------------
      // 🔴 TEXT
      //--------------------------------------------------
      const Text(
        "🔴 LIVE ADLERSCHIESSEN",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),

      const SizedBox(height: 6),

      const Text(
        "Ohne Login zuschauen!\nAlle aktuellen Adlerschießen live verfolgen.",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
        ),
      ),

      const SizedBox(height: 12),

      //--------------------------------------------------
      // ▶ BUTTON
      //--------------------------------------------------
   



ElevatedButton.icon(
  onPressed: () async {
    await _openLiveSelection();
  },
  icon: const Icon(Icons.play_arrow),
  label: const Text("LIVE ansehen"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.red,
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 10,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
),

    ],
  ),
),



              //--------------------------------------------------
              // HINWEIS
              //--------------------------------------------------
              
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