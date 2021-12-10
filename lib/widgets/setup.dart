import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flowder/flowder.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ourtube/widgets/home.dart';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:archive/archive.dart';

import 'package:ourtube/utils/constants.dart' as constants;

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

  bool _updating = false;

  int _filesCompleted = 0;


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

    _appFiles.then((directory) {
      File(p.join(directory.path, 'bin', 'youtube-dl.exe')).exists().then((exists) {
        if(!exists) {
          _appFiles.then((route) => {
            downloadFile(
              constants.youtubeDlUrl,
              File(p.join(directory.path, 'bin', 'youtube-dl.exe')),
              () {
                setState(() { });
                downloadFfmpeg(directory);
              }
            )
          });
        } else {
          setState(() { _updating = true; });
          _appFiles.then((route) => {
            updateYoutubeDl(p.join(route.path, 'bin', 'youtube-dl.exe')),
            setState(() { _filesCompleted++; }),
            downloadFfmpeg(directory)
          });
        }
      });
    });
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
                  Text(_completed && !_didFail ? constants.upToDate : _didFail ? constants.updateError : _updating ? constants.updating : constants.downloading,
                    style: const TextStyle(fontSize: 20)
                  ),
                  if(!_updating && !_completed) ...[
                    Text('$_filesCompleted/2', style: const TextStyle(fontSize: 20)),
                  ],
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
                      label: const Text(constants.goToHome),
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

  void downloadFile(String downloadUrl, File targetFile, Function onDone) {
    Connectivity().checkConnectivity().then((connectivityResult) {
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
            onDone: () { onDone(); setState(() { _filesCompleted++; }); },
            deleteOnCancel: true,
          );
          Flowder.download(downloadUrl, options).then((value) {
            core = value;
          });
          break;
        case ConnectivityResult.none:
          _showToast(context, constants.internetNoAvailable);
      }
    });
  }

  void extractZippedFiles(File sourceFile, String targetDirPath) {
    final bytes = sourceFile.readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        File(p.join(targetDirPath, filename))
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(p.join(targetDirPath, filename)).create(recursive: true);
      }
    }
  }

  void updateYoutubeDl(filePath) {
    Process.run(filePath, ['-U']).then((result) {
      if(result.exitCode == 0) {
        setState(() { _updating = false; });
      } else {
        setState(() { _updating = false; _didFail = true; });
        _showToast(context, constants.updateError);
      }
    });
  }

  downloadFfmpeg(Directory directory) {
    File(p.join(directory.path, 'bin', 'ffmpeg-release-essentials.zip')).exists().then((existsZipFile) {
      Directory(p.join(directory.path, 'bin', 'ffmpeg-release-essentials')).exists().then((existsFfmpeg) {
        if (!existsFfmpeg) {
          if (!existsZipFile) {
            _appFiles.then((route) => {
              downloadFile(
                constants.ffmpegUrl,
                File(p.join(directory.path, 'bin', 'ffmpeg-release-essentials.zip')),
                () {
                  File(p.join(directory.path, 'bin', 'ffmpeg-release-essentials')).exists().then((existsFfmpeg) {
                    if(!existsFfmpeg) {
                      try {
                        extractZippedFiles(File(p.join(directory.path, 'bin', 'ffmpeg-release-essentials.zip')), p.join(directory.path, 'bin', 'ffmpeg-release-essentials'));
                        setState(() { _completed = true; });
                      } on Exception catch (_) {
                        setState(() {
                          _didFail = true;
                        });
                      }
                    } else {
                      setState(() { _completed = true; });
                    }
                  }
                  );
                }
              )
            });
          } else {
            setState(() {
              _updating = true;
            });
            try {
              extractZippedFiles(File(p.join(directory.path, 'bin', 'ffmpeg-release-essentials.zip')), p.join(directory.path, 'bin', 'ffmpeg-release-essentials'));
              setState(() { _completed = true; });
            } on Exception catch (_) {
              setState(() {
                _didFail = true;
              });
            }
          }
        } else {
          setState(() { _completed = true; });
        }
      });
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