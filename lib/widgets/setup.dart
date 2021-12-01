import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flowder/flowder.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ourtube/widgets/home.dart';

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
  final Future<Directory> _appFiles = getApplicationSupportDirectory();
  bool _completed = false;
  bool _didFail = false;

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

    _appFiles.then((directory) =>
        File(p.join(directory.path, 'bin', 'youtube-dl.exe')).exists().then((exists) => {
          if(!exists) {
            _appFiles.then((route) => {
              downloadFiles(route.path)
            })
          } else {
            _appFiles.then((route) => {
              updateFiles(p.join(route.path, 'bin', 'youtube-dl.exe'))
            })
          }
        })
    );
  }

  @override
  void dispose() {
    if(_didFail || !_completed) { core.cancel(); }
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
                  Text(_completed && !_didFail ? 'Everything is up to date' : _didFail ? 'Error on the dependencies update' : 'Updating...',
                    style: const TextStyle(fontSize: 20)
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _completed ? 1 : _controller.value,
                    semanticsLabel: 'Linear progress indicator',
                    color: _completed && !_didFail ? Colors.green : _didFail ? Colors.red : Colors.blue,
                    minHeight: 10,
                  ),
                  if(_completed && !_didFail) ...[
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Home page')), (route) => false);
                      },
                      label: const Text('Continue'),
                      icon: const Icon(Icons.double_arrow_sharp),
                    )
                  ]
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
    String filePath = p.join(path, 'bin', 'youtube-dl.exe');

    Connectivity().checkConnectivity().then((connection) => {
      downloadFilesRun(connection, File(filePath))
    });
  }

  void downloadFilesRun(ConnectivityResult connectivityResult, File targetFile) {
    switch(connectivityResult) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
      case ConnectivityResult.mobile:
        options = DownloaderUtils(
          progressCallback: (current, total) {
            final progress = (current / total);
            _controller.value = progress;
          },
          file: targetFile,
          progress: ProgressImplementation(),
          onDone: () {
            setState(() { _completed = true; });
          },
          deleteOnCancel: true,
        );
        Flowder.download('https://github.com/ytdl-org/youtube-dl/releases/latest/download/youtube-dl.exe', options).then((value) => core = value);
        break;
      case ConnectivityResult.none:
        _showToast(context, "Internet connection is not available");
    }
  }

  void updateFiles(filePath) {
    Process.run(filePath, ['-U']).then((result) {
      if(result.exitCode == 0) {
        setState(() { _completed = true; });
      } else {
        setState(() { _completed = true; _didFail = true; });
        _showToast(context, "Error updating the application dependencies");
      }
    });
  }

  void _showToast(BuildContext context, String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'Ok', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }
}