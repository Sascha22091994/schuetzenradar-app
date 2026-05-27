import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState
    extends State<OnboardingScreen> {

  final PageController _controller = PageController();
  int _index = 0;

  static const int _pageCount = 7; // ✅ angepasst

  //--------------------------------------------------
  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("seenOnboarding", true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(),
      ),
    );
  }

  //--------------------------------------------------
  // ✅ ICON PAGE (STANDARD)
  //--------------------------------------------------
  Widget _buildIconPage({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Container(
            padding: const EdgeInsets.all(30),
            
            decoration: BoxDecoration(
  color: Colors.green.shade300,
  shape: BoxShape.circle,
  boxShadow: [
    BoxShadow(
      color: Colors.green.withValues(alpha:0.25),
      blurRadius: 18,
      spreadRadius: 2,
      offset: const Offset(0, 8),
    ),
  ],
),

            child: Icon(
              icon,
              size: 60,
              color: Colors.green.shade900,
            ),
          ),

          const SizedBox(height: 40),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              
  fontWeight: FontWeight.w700,
  color: Color(0xFF1B5E20),

            ),
          ),

          const SizedBox(height: 15),

          Text(
            text,
            textAlign: TextAlign.center,
        
style: const TextStyle(
  fontSize: 15,
  height: 1.5,
  color: Colors.black87,
),

          ),
        ],
      ),
    );
  }

  //--------------------------------------------------
  // ✅ KALENDER PAGE
  //--------------------------------------------------
Widget _buildCalendarPage() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

    Container(
  padding: const EdgeInsets.all(24),
  decoration: BoxDecoration(
    color: Colors.green.shade300,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.green.withValues(alpha:0.25),
        blurRadius: 18,
        spreadRadius: 2,
        offset: const Offset(0, 8),
      ),
    ],
  ),
  child: Icon(
    Icons.calendar_month,
    size: 50,
    color: Colors.green.shade900,
  ),
),


        const SizedBox(height: 30),

        // Mini Kalender Preview
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: List.generate(3, (row) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (col) {
                  return Container(
                    margin: const EdgeInsets.all(2),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: (row == 1 && col == 3)
                          ? Colors.green
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              );
            }),
          ),
        ),

        const SizedBox(height: 40),

        const Text(
          "Alle Termine im Blick",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        const Text(
          "Plane deine Saison im Kalender und markiere deine Lieblingsfeste 📅⭐",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    ),
  );
}


  //--------------------------------------------------
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pageCount, (i) {
        final active = i == _index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
 active
    ? const Color(0xFF1B5E20)
    : Colors.grey.shade300,

            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  //--------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            
colors: [
  Color(0xFFE8F5E9),
  Color(0xFFC8E6C9),
],

          ),
        ),

        child: SafeArea(
          child: Column(
            children: [

              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text("Überspringen"),
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) =>
                      setState(() => _index = i),

                  children: [

_buildIconPage(
  icon: Icons.map,
  title: "Alle Schützenfeste. Eine App.",
  text: "Finde sofort die besten Feste in deiner Region – auf Karte oder Liste 🎯",
),

_buildIconPage(
  icon: Icons.notifications,
  title: "Verpass nie wieder dein Fest",
  text: "Speichere deine Favoriten und hab sie jederzeit im Blick ⭐",
),

_buildIconPage(
  icon: Icons.add_circle,
  title: "Werde Teil der Community",
  text: "Füge ganz einfach neue Feste oder News hinzu und hilf anderen ✍️",
),

_buildIconPage(
  icon: Icons.public,
  title: "Dein Fest im Rampenlicht",
  text: "Zeig dein Fest mit Website, Social Media & Highlights 🎪",
),


_buildIconPage(
  icon: Icons.emoji_events,
  title: "Adlerschießen – live & interaktiv",
  text: "Dokumentiere als Moderator jeden Schuss oder verfolge das Geschehen live mit 🦅",
),



// Kalender bleibt gleich vom Text leicht optimiert:
_buildCalendarPage(),
// Text darin ändern zu:
_buildIconPage(
  icon: Icons.star,
  title: "Und das war erst der Anfang",
  text: "Freu dich auf ständig neue Features und Updates 🚀",
),
                  ],
                ),
              ),

              _buildDots(),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF2E7D32),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  ),
                    onPressed: () {
                      if (_index == _pageCount - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _index == _pageCount - 1
                          ? "Los geht’s 🚀"
                          : "Weiter",
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}