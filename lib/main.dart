import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shop_cutesy/screens/auth/log_in.dart';
import 'package:shop_cutesy/screens/auth/reset_password.dart';
import 'package:shop_cutesy/screens/auth/sign_up.dart';
import 'package:shop_cutesy/screens/cart_page.dart';
import 'package:shop_cutesy/screens/home_page.dart';
import 'package:shop_cutesy/screens/coupon_page.dart';
import 'package:shop_cutesy/screens/profile_page.dart';
import 'package:shop_cutesy/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      navigatorObservers: [routeObserver],
      title: 'Shop Cutesy',
      theme: ThemeData(
        fontFamily: 'Vollkorn',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE370EE),
          primary: const Color(0xFFE370EE),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Color(0xFF666565),
          ),
          prefixIconColor: Color(0xFF666565),
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/home': (context) => const HomePage(),
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/cart': (context) => const CartPage(),
        '/profile': (context) => const ProfilePage(),
        '/reset': (context) => const ResetPage(),
        '/offer': (context) => const CouponPage(),
      },
    );
  }
}