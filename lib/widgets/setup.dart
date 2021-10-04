import 'package:flutter/material.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
    );
  }

}