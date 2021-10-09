import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ourtube/widgets/home.dart';
import 'package:flutter/foundation.dart';
import 'package:ourtube/widgets/setup.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  static Future<Directory?>? _appFiles;
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    switch(Theme.of(context).platform) {
      case TargetPlatform.android:
        _appFiles = getApplicationDocumentsDirectory();
        break;
      case TargetPlatform.fuchsia:
        throw UnsupportedError("FuchsiaOS is an unsupported platform");
      case TargetPlatform.iOS:
        throw UnsupportedError("iOS is an unsupported platform");
      case TargetPlatform.linux:
        throw UnsupportedError("Linux is an unsupported platform");
      case TargetPlatform.macOS:
        throw UnsupportedError("MacOS is an unsupported platform");
      case TargetPlatform.windows:
        _appFiles = getApplicationDocumentsDirectory();
        break;
    }

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isInstalled() ? const MyHomePage(title: 'Home Page') : const SetupPage(title: 'Setup'),
    );
  }

  bool isInstalled() {
    String path = "";
    _appFiles!.then((value) => path = value!.path);
    return Directory(p.join(path, '.ourtube')).existsSync();
  }
}
