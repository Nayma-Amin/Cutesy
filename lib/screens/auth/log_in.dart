import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shop_cutesy/screens/home_page.dart';
import 'package:shop_cutesy/screens/services/authentication.dart';
import 'package:shop_cutesy/utils/purple_box.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool remember = false;
  bool _loading = false;
  bool _obscurePassword = true;

  void handleLogin() async {
  setState(() => _loading = true);

  final email = _email.text.trim();
  final password = _password.text.trim();

  try {
    final result = await AuthService().loginUser(email: email, password: password);

    if (result != null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result)));
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) throw "Unable to get user info.";

    final uid = firebaseUser.uid;
    final firestore = FirebaseFirestore.instance;

    final bannedDoc = await firestore.collection("banned_users").doc(uid).get();
    if (bannedDoc.exists) {
      final reason = bannedDoc.data()?["reason"] ?? "No reason provided";
      _showBlockedDialog("banned", reason);
      setState(() => _loading = false);
      await FirebaseAuth.instance.signOut();
      return;
    }

    final restrictedDoc = await firestore.collection("restricted_users").doc(uid).get();
    if (restrictedDoc.exists) {
      final reason = restrictedDoc.data()?["reason"] ?? "No reason provided";
      _showBlockedDialog("restricted", reason);
      setState(() => _loading = false);
      await FirebaseAuth.instance.signOut();
      return;
    }

    final userDoc = await firestore.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      _showBlockedDialog("unknown", "You do not have access to the app.");
      setState(() => _loading = false);
      await FirebaseAuth.instance.signOut();
      return;
    }

    TextInput.finishAutofillContext(shouldSave: remember);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  } catch (e) {
    setState(() => _loading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

void _showBlockedDialog(String type, String reason) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(type == "banned"
          ? "You are banned"
          : type == "restricted"
              ? "You are restricted"
              : "Access denied"),
      content: Text(type == "banned"
          ? "You are banned from our app because: $reason"
          : type == "restricted"
              ? "You are restricted from our app because: $reason"
              : reason),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPink,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: SingleChildScrollView(
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset("assets/images/cutesy.png", height: 40),
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDAB7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter User Email",
                        hintStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDAB7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter Password",
                        hintStyle: const TextStyle(color: Colors.white),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Checkbox(
                        value: remember,
                        onChanged: (v) => setState(() => remember = v!),
                      ),
                      const Text("Remember Password"),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _loading ? null : handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnPurple,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Log In",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Forgot Password? "),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, "/reset"),
                        child: const Text(
                          "Reset Password Here!",
                          style: TextStyle(
                            color: btnPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don’t Have an Account? "),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, "/signup"),
                        child: const Text(
                          "Sign Up Here",
                          style: TextStyle(
                            color: btnPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
