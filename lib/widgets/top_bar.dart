import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopBar extends StatelessWidget {
  final VoidCallback onMenuTap;

  const TopBar({
    super.key,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMenuTap,
            child: const Icon(
              Icons.menu,
              size: 30,
              color: Colors.black,
            ),
          ),

          const SizedBox(width: 10),

          Image.asset(
            "assets/images/cutesy.png",
            width: 90,
          ),

          const Spacer(),

          if (user != null)
            GestureDetector(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                final prefs = await SharedPreferences.getInstance();
                prefs.remove("savedEmail");
                prefs.remove("savedPass");

                Navigator.pushReplacementNamed(context, "/home");
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB564F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Log Out",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

          if (user == null)
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, "/login"),
              child: const Text(
                "Log In",
                style: TextStyle(
                  color: Color(0xFFB564F7),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}