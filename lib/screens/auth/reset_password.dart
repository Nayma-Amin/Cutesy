import 'package:flutter/material.dart';
import 'package:shop_cutesy/screens/services/authentication.dart';
import 'package:shop_cutesy/utils/purple_box.dart';

class ResetPage extends StatefulWidget {
  const ResetPage({super.key});

  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  final _email = TextEditingController();
  bool loading = false;

  void sendReset() async {
  setState(() => loading = true);

  String? res = await AuthService().resetPassword(_email.text.trim());

  setState(() => loading = false);

  if (res == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reset email sent!")),
    );

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/login");
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPink,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("assets/images/cutesy.png", height: 40),
              const SizedBox(height: 40),

              inputBox(_email, "Enter User Email"),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: loading ? null : sendReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnPurple,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Send Reset Mail",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
