import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flowder/flowder.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
  late Future<Directory?>? _appFiles;
  bool _completed = false;
  ConnectivityResult _connectionState = ConnectivityResult.ethernet;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this
    )..addListener(() {
      setState(() {});
    });
  }

  @override void didChangeDependencies() {
    super.didChangeDependencies();
    fillConnectivity();
    fillInstallPath();

    _appFiles!.then((directory) =>
        File(p.join(directory!.path, 'bin', 'youtube-dl.exe')).exists().then((exists) => {
          if(!exists) {
            _appFiles!.then((route) => {
              downloadFiles(route!.path)
            })
          } else {
            setState(() { _completed = true; })
            }
        })
    );
  }

  @override
  void dispose() {
    core.cancel();
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
                        fontSize: 20
                    )
                  ),
                  LinearProgressIndicator(
                    value: _completed ? 1 : _controller.value,
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

  void downloadFiles(String path) {
    switch(_connectionState) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
      case ConnectivityResult.mobile:
        options = DownloaderUtils(
          progressCallback: (current, total) {
            final progress = (current / total);
            _controller.value = progress;
          },
          file: File(p.join(path, 'bin', 'youtube-dl.exe')),
          progress: ProgressImplementation(),
          onDone: () => setState(() { _completed = true; }),
          deleteOnCancel: true,
        );
        Flowder.download('https://github.com/ytdl-org/youtube-dl/releases/latest/download/youtube-dl.exe', options).then((value) => core = value);
        break;
      case ConnectivityResult.none:
        break;
    }
  }

  void fillInstallPath() {
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
        _appFiles = getApplicationSupportDirectory();
        break;
    }
  }

  void fillConnectivity() {
    Connectivity().checkConnectivity().then((connection) => setState(() { _connectionState = connection; }));
  }

  void _showToast(BuildContext context) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Text('Added to favorite'),
        action: SnackBarAction(label: 'UNDO', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }
}