import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeText extends StatelessWidget {
  const WelcomeText({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'App Ver 1.1',
        style: GoogleFonts.poppins(
          color: Colors.white, // Change color for better visibility
          fontSize: 10, // Increased font size for impact
          fontWeight: FontWeight.normal,
          letterSpacing: 1.2, // Adds spacing for a modern look
          
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
