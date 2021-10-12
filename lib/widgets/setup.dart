import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flowder/flowder.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late DownloaderUtils options;
  late DownloaderCore core;
  late final String path = '';
  bool _completed = false;
  ConnectivityResult _connectionState = ConnectivityResult.none;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this
    )..addListener(() {
      setState(() {});
    });
    super.initState();

    var connectivityResult = Connectivity().checkConnectivity();
    connectivityResult.then((connection) => setState(() { _connectionState = connection; }));

    options = DownloaderUtils(
      progressCallback: (current, total) {
        final progress = (current / total);
        _controller.value = progress;
      },
      file: File('$path/5MB.zip'),
      progress: ProgressImplementation(),
      onDone: () => setState(() { _completed = true; }),
      deleteOnCancel: true,
    );

    var core = Flowder.download('http://ipv4.download.thinkbroadband.com/5MB.zip', options);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                  Text(_completed ? 'Everything is up to date' : 'Updating...',
                    style: const TextStyle(
                        fontSize: 30
                    )
                  ),
                  LinearProgressIndicator(
                    value: _controller.value,
                    semanticsLabel: 'Linear progress indicator',
                    color: _completed ? Colors.green : Colors.blue,
                    minHeight: 10,
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

  void downloadFiles(ConnectivityResult connectionStatus) {
    switch(connectionStatus) {
      case ConnectivityResult.wifi:
      // TODO: Handle this case.
        break;
      case ConnectivityResult.ethernet:
      // TODO: Handle this case.
        break;
      case ConnectivityResult.mobile:
      // TODO: Handle this case.
        break;
      case ConnectivityResult.none:
      // TODO: Handle this case.
        break;
    }
  }
}