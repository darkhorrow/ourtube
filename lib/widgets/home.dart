import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:validators/validators.dart' as validator;
import 'package:validators/sanitizers.dart' as sanitizer;

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _validationError = false;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_checkUrl);
  }

  void _trimInput(String input) {
    final String _newValue = sanitizer.trim(_controller.text);
    _controller.value = TextEditingValue(
      text: _newValue,
      selection: TextSelection.fromPosition(
        TextPosition(offset: _controller.selection.base.offset != _newValue.length ? _controller.selection.base.offset : _newValue.length),
      ),
    );
  }

  void _checkUrl() {
    bool _validURL = validator.isURL(sanitizer.trim(_controller.text));
    !_validURL ? setState(() { _validationError = true; }) : setState(() { _validationError = false; });
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
                  TextField(
                    style: const TextStyle(
                      fontSize: 30
                    ),
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Enter an URL',
                      errorText: _validationError ? 'Not a valid URL' : null,
                    ),
                    onChanged: (String input) { _trimInput(input); },
                  )
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