import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'add_compte_camion.dart';
import 'login.dart';
import 'reset_password.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Platform.isAndroid
      ? await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyABtXN4k4KgUIYshkhAeEMwhDshirfScvY",
          appId: "1:698063590477:android:98603e870aed1e8486b804",
          messagingSenderId: "698063590477",
          projectId: "camionpoubelle-30842"))
      : await Firebase.initializeApp();
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => Login(),
        '/reset_password': (context) => ResetPasswordPage(),




      },
    );
  }
}

