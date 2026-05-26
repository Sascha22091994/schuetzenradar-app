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

  static const int _pageCount = 6;

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
  // ✅ IMAGE SLIDER
  //--------------------------------------------------
  Widget _imageSlider(List<String> images) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                images[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image, size: 50),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  //--------------------------------------------------
  Widget _buildPage({
    required List<String> images,
    required String title,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          _imageSlider(images),

          const SizedBox(height: 30),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------
  // ✅ ICON PAGE (für letzte Slide)
  //--------------------------------------------------
  Widget _buildIconPage({
    required String title,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _iconItem(Icons.map),
              _iconItem(Icons.star),
              _iconItem(Icons.navigation),
              _iconItem(Icons.edit),
              _iconItem(Icons.public),
              _iconItem(Icons.emoji_events),
            ],
          ),

          const SizedBox(height: 40),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  //--------------------------------------------------
  Widget _iconItem(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.green.shade700,
        size: 26,
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
                active ? Colors.green : Colors.grey.shade400,
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
              Color(0xFFF3F5F4),
              Colors.white,
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

                    _buildPage(
                      images: [
                        "assets/onboarding/01_map.jpg",
                        "assets/onboarding/01_list.png",
                      ],
                      title: "Finde alle Schützenfeste",
                      text:
                          "Alle Events in deiner Region – als Liste oder auf der Karte 🎯",
                    ),

                    _buildPage(
                      images: [
                        "assets/onboarding/info.png",
                      ],
                      title: "Nie wieder etwas verpassen",
                      text:
                          "Speichere Favoriten und navigiere direkt zum Fest 📍",
                    ),

                    _buildPage(
                      images: [
                        "assets/onboarding/03_festmelden.jpg",
                        "assets/onboarding/03_newsmelden.jpg",
                      ],
                      title: "Mach die App besser",
                      text:
                          "Trage neue Feste oder News ganz einfach ein ✍️",
                    ),

                    _buildPage(
                      images: [
                        "assets/onboarding/05_more.jpg",
                      ],
                      title: "Zeig dein Fest",
                      text:
                          "Website, Instagram & Highlights direkt sichtbar 🎪",
                    ),

                    _buildPage(
                      images: [
                        "assets/onboarding/a04_adler.jpg",
                        "assets/onboarding/04_schießen.png",
                      ],
                      title: "Live dabei sein",
                      text:
                          "Adlerschießen in Echtzeit verfolgen 🦅",
                    ),

                    //--------------------------------------------------
                    // ✅ ICON SLIDE
                    //--------------------------------------------------
                    _buildIconPage(
                      title: "Und vieles mehr",
                      text:
                          "Entdecke ständig neue Features 🎉",
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
                    onPressed: () {
                      if (_index == _pageCount - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration:
                              const Duration(milliseconds: 300),
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