import 'package:flutter/material.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkInstallation() {

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Container(),
          ),
          Expanded(
            flex: 6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: _controller.value,
                    semanticsLabel: 'Spinner setup indicator',
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(),
          )
        ],
      )
    );
  }

}