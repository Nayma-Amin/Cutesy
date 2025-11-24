import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController c1;
  late AnimationController c2;
  late AnimationController c3;
  late AnimationController c4;
  late AnimationController c5;
  late AnimationController logoAnim;

  late Animation<double> s1;
  late Animation<double> s2;
  late Animation<double> s3;
  late Animation<double> s4;
  late Animation<double> s5;
  late Animation<double> logoScale;

  @override
  void initState() {
    super.initState();

    const popDuration = Duration(milliseconds: 999);

    c1 = AnimationController(vsync: this, duration: popDuration);
    c2 = AnimationController(vsync: this, duration: popDuration);
    c3 = AnimationController(vsync: this, duration: popDuration);
    c4 = AnimationController(vsync: this, duration: popDuration);
    c5 = AnimationController(vsync: this, duration: popDuration);

    logoAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    s1 = CurvedAnimation(parent: c1, curve: Curves.easeOutBack);
    s2 = CurvedAnimation(parent: c2, curve: Curves.easeOutBack);
    s3 = CurvedAnimation(parent: c3, curve: Curves.easeOutBack);
    s4 = CurvedAnimation(parent: c4, curve: Curves.easeOutBack);
    s5 = CurvedAnimation(parent: c5, curve: Curves.easeOutBack);
    logoScale = CurvedAnimation(parent: logoAnim, curve: Curves.easeOutBack);

    Future.delayed(const Duration(milliseconds: 200), () => c1.forward());
    Future.delayed(const Duration(milliseconds: 500), () => c2.forward());
    Future.delayed(const Duration(milliseconds: 800), () => c3.forward());
    Future.delayed(const Duration(milliseconds: 1100), () => c4.forward());
    Future.delayed(const Duration(milliseconds: 1400), () => c5.forward());
    Future.delayed(const Duration(milliseconds: 1700), () => logoAnim.forward());

    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    c1.dispose();
    c2.dispose();
    c3.dispose();
    c4.dispose();
    c5.dispose();
    logoAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE7EF),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.pinkAccent.withOpacity(0.35),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.purpleAccent.withOpacity(0.30),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color.fromARGB(255, 219, 117, 250).withOpacity(0.28),
              ),
            ),
          ),

          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ScaleTransition(
                  scale: s1,
                  child: circle(330, const Color(0xFFF8C7D9)),
                ),
                ScaleTransition(
                  scale: s2,
                  child: circle(270, const Color(0xFFF5A7C4)),
                ),
                ScaleTransition(
                  scale: s3,
                  child: circle(210, const Color(0xFFF08DB5)),
                ),
                ScaleTransition(
                  scale: s4,
                  child: circle(160, const Color(0xFFEA74AB)),
                ),
                ScaleTransition(
                  scale: s5,
                  child: circle(120, const Color(0xFFEC6FA6)),
                ),

                ScaleTransition(
                  scale: logoScale,
                  child: Image.asset(
                    "assets/images/cutesy.png",
                    width: 120,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}