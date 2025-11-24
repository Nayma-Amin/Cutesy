import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController c1, c2, c3, c4, c5, logoAnim;

  late Animation<double> s1, s2, s3, s4, s5;
  late Animation<double> o1, o2, o3, o4, o5;
  late Animation<double> logoScale;

  @override
  void initState() {
    super.initState();

    const popDuration = Duration(milliseconds: 1200);

    c1 = AnimationController(vsync: this, duration: popDuration);
    c2 = AnimationController(vsync: this, duration: popDuration);
    c3 = AnimationController(vsync: this, duration: popDuration);
    c4 = AnimationController(vsync: this, duration: popDuration);
    c5 = AnimationController(vsync: this, duration: popDuration);

    logoAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    s1 = CurvedAnimation(parent: c1, curve: Curves.easeOutCubic);
    s2 = CurvedAnimation(parent: c2, curve: Curves.easeOutCubic);
    s3 = CurvedAnimation(parent: c3, curve: Curves.easeOutCubic);
    s4 = CurvedAnimation(parent: c4, curve: Curves.easeOutCubic);
    s5 = CurvedAnimation(parent: c5, curve: Curves.easeOutCubic);

    o1 = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 40),
    ]).animate(c1);

    o2 = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 40),
    ]).animate(c2);

    o3 = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 40),
    ]).animate(c3);

    o4 = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 40),
    ]).animate(c4);

    o5 = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 40),
    ]).animate(c5);

    logoScale = CurvedAnimation(parent: logoAnim, curve: Curves.easeOutBack);
/*
    Future.delayed(const Duration(milliseconds: 200), () => c1.forward());
    Future.delayed(const Duration(milliseconds: 600), () => c2.forward());
    Future.delayed(const Duration(milliseconds: 1000), () => c3.forward());
    Future.delayed(const Duration(milliseconds: 1400), () => c4.forward());
    Future.delayed(const Duration(milliseconds: 1800), () => c5.forward());
    Future.delayed(const Duration(milliseconds: 2300), () => logoAnim.forward());
*/
    Future.delayed(const Duration(milliseconds: 200), () {
      c1.repeat();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      c2.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      c3.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      c4.repeat();
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      c5.repeat();
    });

    Future.delayed(const Duration(milliseconds: 2300), () {
      logoAnim.forward();
    });

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
          Positioned(top: -80, left: -60, child: blurredPink()),
          Positioned(top: 120, right: -40, child: blurredPurple()),
          Positioned(bottom: -60, left: -40, child: blurredLilac()),

          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                blendedCircle(330, const Color(0xFFF8C7D9), s1, o1),
                blendedCircle(270, const Color(0xFFF5A7C4), s2, o2),
                blendedCircle(210, const Color(0xFFF08DB5), s3, o3),
                blendedCircle(160, const Color(0xFFEA74AB), s4, o4),
                blendedCircle(120, const Color(0xFFEC6FA6), s5, o5),

                ScaleTransition(
                  scale: logoScale,
                  child: Image.asset("assets/images/cutesy.png", width: 120),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget blendedCircle(
    double size,
    Color color,
    Animation<double> scale,
    Animation<double> opacity,
  ) {
    return ScaleTransition(
      scale: scale,
      child: FadeTransition(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.9),
          ),
        ),
      ),
    );
  }

  Widget blurredPink() => Container(
    width: 220,
    height: 220,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.pinkAccent.withOpacity(0.30),
    ),
  );

  Widget blurredPurple() => Container(
    width: 160,
    height: 160,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.purpleAccent.withOpacity(0.28),
    ),
  );

  Widget blurredLilac() => Container(
    width: 260,
    height: 260,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color.fromARGB(255, 219, 117, 250).withOpacity(0.28),
    ),
  );
}