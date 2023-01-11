import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      cursorColor: Colors.black,
      style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
      decoration: InputDecoration(
        fillColor: Colors.grey[50],
        filled: true,
        labelText: label,
        labelStyle: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
