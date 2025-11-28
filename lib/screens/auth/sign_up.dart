import 'package:flutter/material.dart';
import 'package:shop_cutesy/screens/services/authentication.dart';
import 'package:shop_cutesy/utils/purple_box.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  bool _agree = false;
  bool _loading = false;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  void handleSignup() async {
    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must accept Terms & Conditions")),
      );
      return;
    }

    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => _loading = true);

    String? result = await AuthService().registerUser(
      name: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text.trim(),
      phone: _phone.text.trim(),
      address: _address.text.trim(),
    );

    setState(() => _loading = false);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sign Up Completed!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacementNamed(context, "/login");
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPink,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 60),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/cutesy.png", height: 40),
                const SizedBox(height: 40),

                inputBox(_name, "Enter User Name"),
                const SizedBox(height: 16),

                inputBox(_email, "Enter User Email"),
                const SizedBox(height: 16),

                inputBox(_phone, "Enter User Contact"),
                const SizedBox(height: 16),

                inputBox(
                  _password,
                  "Enter Password",
                  obscure: _obscurePassword,
                  toggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                const SizedBox(height: 16),

                inputBox(
                  _confirm,
                  "Confirm Password",
                  obscure: _obscureConfirm,
                  toggleObscure: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
                  },
                ),
                const SizedBox(height: 16),
                
                inputBox(_address, "Address : House No. Street, Road..."),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Checkbox(
                      value: _agree,
                      onChanged: (v) => setState(() => _agree = v!),
                    ),
                    const Text("I agree to Terms and Conditions."),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, "/term"),
                      child: const Text(
                        " Read Here",
                        style: TextStyle(
                          color: btnPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: _loading ? null : handleSignup,
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
                          "Sign Up",
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
                    const Text("Already Have an Account? "),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, "/login"),
                      child: const Text(
                        "Log In Here",
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
    );
  }
}
