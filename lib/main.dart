import 'package:flutter/material.dart';
import 'package:login_firebase/screens/feed.dart';
import 'package:login_firebase/screens/login_page.dart';
import 'package:login_firebase/screens/newpost.dart';
import 'package:login_firebase/screens/profile.dart';
import 'package:login_firebase/screens/register_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Red Social",
      initialRoute: "/LoginPage",
      routes: {
        "/LoginPage": (context) => const LoginPage(),
        "/RegisterPage": (context) => const RegisterPage(),
        "/feed": (context) => FeedPage(),
        '/newpost': (context) => CreatePostPage(),
        "/profile": (context) => ProfilePage(),
      },
    );
  }
}
