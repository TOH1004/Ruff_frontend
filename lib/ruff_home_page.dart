import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'homepage_chat2.dart';

class RuffHomePage extends StatelessWidget {
  const RuffHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3075FF), // Blue background
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Text
            Column(
              children: [
                Text(
                  "RUFF",
                  style: GoogleFonts.climateCrisis(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Campus Security",
                  style: GoogleFonts.tiltWarp(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Dog Image (make sure you add it to assets)
            Image.asset(
              "assets/dog.png",
              height: 350,
            ),

            const SizedBox(height: 60),

            // Start Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30)),
                  ),
                  minimumSize: const Size(double.infinity, 55),
                ),
                onPressed: () {
                  Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RuffAppScreen()),
                  );
                },
                child: Text(
                  "Start the Journey",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
