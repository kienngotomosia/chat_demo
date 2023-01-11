import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/pages/pages.dart';
import 'package:flutter_chat_demo/providers/auth_provider.dart';
import 'package:flutter_chat_demo/widgets/button/custom_button.dart';
import 'package:flutter_chat_demo/widgets/text_field/custom_text_form_field.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    AuthProvider authProvider = Provider.of<AuthProvider>(context);
    switch (authProvider.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: "Sign in fail");
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: "Sign in canceled");
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: "Sign in success");
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
              label: 'Login',
              onTap: () async {
                authProvider
                    .login(
                  _emailController.text.trim(),
                  _passwordController.text.trim(),
                )
                    .then((value) {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => HomePage()));
                });
              },
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                authProvider
                    .login(_emailController.text.trim(),
                        _passwordController.text.trim())
                    .then((value) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => LoginScreen()));
                });
              },
              child: Text('Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
