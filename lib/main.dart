import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'pages/home.dart';

void main() {
  if (Platform.isAndroid) {
    WidgetsFlutterBinding.ensureInitialized();
    [
      Permission.location,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
    ].request().then((status) {
      runApp(const MyApp());
    });
  } else {
      runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pill O\'Clock manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(title: 'Pill O\' Clock manager'),
    );
  }
}

