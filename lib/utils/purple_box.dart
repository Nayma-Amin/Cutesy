import 'package:flutter/material.dart';

const Color bgPink = Color(0xFFFCECF4);
const Color fieldPurple = Color(0xFFDAB7FF);
const Color btnPurple = Color(0xFFB564F7);

Widget inputBox(
  TextEditingController controller,
  String hint, {
  bool obscure = false,
  VoidCallback? toggleObscure,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: fieldPurple,
      borderRadius: BorderRadius.circular(12),
    ),
    child: TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        suffixIcon: toggleObscure == null
            ? null
            : IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: toggleObscure,
              ),
      ),
    ),
  );
}