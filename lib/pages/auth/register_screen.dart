import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/pages/pages.dart';
import 'package:flutter_chat_demo/providers/auth_provider.dart';
import 'package:flutter_chat_demo/widgets/button/custom_button.dart';
import 'package:flutter_chat_demo/widgets/text_field/custom_text_form_field.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    switch (authProvider.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: "Register  fail");
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: "Register canceled");
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: "Register success");
        break;
      default:
        break;
    }
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomTextFormField(
              controller: _nameController,
              label: 'Nickname',
            ),
            const SizedBox(height: 12),
            CustomTextFormField(
              controller: _emailController,
              label: 'Email',
            ),
            const SizedBox(height: 12),
            CustomTextFormField(
              controller: _passwordController,
              label: 'Password',
              obscureText: true,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Register',
              onTap: () {
                authProvider
                    .register(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                  _nameController.text.trim(),
                )
                    .then((isSuccess) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(),
                    ),
                  );
                })
                  .catchError((error, stackTrace) {
                    Fluttertoast.showToast(msg: error.toString());
                    authProvider.handleException();
                  });
              },
            ),
          ],
        ),
      ),
    );
  }
}
