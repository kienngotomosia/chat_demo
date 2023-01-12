import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/constants/color_constants.dart';
import 'package:flutter_chat_demo/firebase_options.dart';
import 'package:flutter_chat_demo/main.dart';
import 'package:flutter_chat_demo/pages/auth/login_screen.dart';
import 'package:flutter_chat_demo/providers/auth_provider.dart';
import 'package:flutter_notification/flutter_notification.dart';
import 'package:provider/provider.dart';

import '../pages.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      // just delay for showing this slash page clearer because it too fast
      checkSignedIn();
    });
  }

  void checkSignedIn() async {
    AuthProvider authProvider = context.read<AuthProvider>();
    bool isLoggedIn = await authProvider.isLoggedIn();
    if (isLoggedIn) {
      FlutterNotification flutterNotification = FlutterNotification();
      await flutterNotification.initialize(
        DefaultFirebaseOptions.currentPlatform,
        iconLink: "@mipmap/ic_launcher",
        key: navigatorKey, backGround: (){}, foreGround: (){},
      );
      print("in demo >>>>>"+flutterNotification.hashCode.toString());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              "images/app_icon.png",
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 20,
              height: 20,
              child:
                  CircularProgressIndicator(color: ColorConstants.themeColor),
            ),
          ],
        ),
      ),
    );
  }
}
