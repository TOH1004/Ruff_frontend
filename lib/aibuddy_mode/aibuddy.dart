import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../bottom_navigation.dart';
import 'caring.dart';
import 'silent.dart';
import 'chatty.dart';

class AIBuddyPage extends StatefulWidget {
  const AIBuddyPage({super.key});

  @override
  State<AIBuddyPage> createState() => _AIBuddyPageState();
}

class _AIBuddyPageState extends State<AIBuddyPage> {
  int _selectedIndex = 1; // current page index for BottomNavBar

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3075FF), // blue background
appBar: AppBar(
  systemOverlayStyle: SystemUiOverlayStyle.light,
  backgroundColor: Colors.transparent,
  elevation: 0,
  iconTheme: const IconThemeData(
    color: Colors.white, // make the back arrow white
    size: 28,            // optional: make it bigger
  ),
  title: const Text(
    'AI Buddy',
    style: TextStyle(
      fontFamily: 'SF Pro',
      fontSize: 26,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    ),
  ),
  centerTitle: true,
),

      body: Stack(
        children: [
          // Big white background
          Container(
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
          ),

          // Mode Cards
          SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                const SizedBox(height: 30), // padding from top
                _buildModeCard(
                  title: 'SILENT MODE',
                  description:
                      "I'm here with you. I won't ask much, only when it matters. I'll keep things calm, play gentle music, and quiet for your side. ",
                  buttonText: 'Let\'s Chat!',
                  color: const Color(0xFF3075FF),
                  imagePath: 'assets/silent.png',
                  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SilentModePage()),
    );
  },
                ),
                const SizedBox(height: 30),
                _buildModeCard(
                  title: 'CHATTY MODE',
                  description:
                      "Let's talk, laugh, and make the time fly together! I'll ask questions, share fun, and keep you company.",
                  buttonText: 'Let\'s Chat!',
                  color: const Color(0xFF3075FF),
                  imagePath: 'assets/chatty.png',
                  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SilentModePage()),
    );
  },
                ),
                const SizedBox(height: 30),
                _buildModeCard(
                  title: 'CARING MODE',
                  description:
                      "I'm here to comfort you and make sure you feel safe. You're not alone, I'm by your side.",
                  buttonText: 'Let\'s Chat!',
                  color: const Color(0xFF3075FF),
                  imagePath: 'assets/caring.png',
                  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CaringModePage()),
    );
  },
                ),
                const SizedBox(height: 100), // padding bottom
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Add your navigation logic here
        },
      ),
    );
  }

 Widget _buildModeCard({
  required String title,
  required String description,
  required String buttonText,
  required Color color,
  required String imagePath,
  required VoidCallback onPressed,
}) {
  return Stack(
    clipBehavior: Clip.none, // allow button to overflow
    children: [
      // The main card
      Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imagePath,
                  width: 180,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'tiltWarp',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 12,
                        color: Color.fromARGB(255, 121, 121, 121),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20), // leave space for button overlap
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Positioned button overlapping the shadow
Positioned(
        bottom: -10,
        right: 12,
        child: SizedBox(
          height: 36,
          child: ElevatedButton(
            onPressed: onPressed, // use the callback
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontFamily: 'tiltWarp',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ],
  );

}
}
