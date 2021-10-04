import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ourtube/widgets/home.dart';

import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  static final Future<Directory?>? _appDocDir = getApplicationDocumentsDirectory();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    _appDocDir!.then((value) => print(value!.path));
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
