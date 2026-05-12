/*import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  //--------------------------------------------------
  // ✅ INIT (Animation)
  //--------------------------------------------------
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  //--------------------------------------------------
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //--------------------------------------------------
  // ✅ LINK ÖFFNEN
  //--------------------------------------------------
  Future<void> _openPayPal() async {
    final uri = Uri.parse("paypal.me/SaschaLanghorst"); // 👈 HIER DEIN LINK

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Konnte Link nicht öffnen';
    }
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Support"),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              //--------------------------------------------------
              // 🍻 ICON / SYMBOL
              //--------------------------------------------------
              const Text(
                "🍺",
                style: TextStyle(fontSize: 70),
              ),

              const SizedBox(height: 20),

              //--------------------------------------------------
              // TEXT
              //--------------------------------------------------
              const Text(
                "Wenn dir die App gefällt und du mich unterstützen möchtest,\n"
                "dann gib mir doch einfach ein Bier aus 🍻",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Vielen Dank für deinen Support 🙌",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              //--------------------------------------------------
              // ✅ ANIMIERTER BUTTON
              //--------------------------------------------------
              ScaleTransition(
                scale: _scaleAnimation,
                child: ElevatedButton.icon(
                  onPressed: _openPayPal,

                  icon: const Icon(Icons.local_drink),

                  label: const Text(
                    "🍺 Bier ausgeben",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              //--------------------------------------------------
              // OPTIONAL KLEINER HINWEIS
              //--------------------------------------------------
              const Text(
                "Unterstütze die Weiterentwicklung von SchützenRadar ❤️",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/