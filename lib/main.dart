import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ourtube/widgets/setup.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ourtube Downloader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SetupPage(title: 'Setup'),
    );
  }
}
