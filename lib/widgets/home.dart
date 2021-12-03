import 'dart:io';

import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:validators/sanitizers.dart' as sanitizer;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _validationError = true;
  bool _preDownloadError = true;
  bool _searchDone = false;
  bool _showDownloadButton = false;
  bool _downloading = false;
  bool _isAudio = false;

  String _thumbnailPath = '';
  final _controller = TextEditingController();

  late AnimationController _animationController;
  late final Future<Directory?> _downloadDirectory = getDownloadsDirectory();
  final Future<Directory> _appFiles = getApplicationSupportDirectory();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_checkUrl);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _trimInput(String input) {
    final String _newValue = sanitizer.trim(_controller.text);
    _controller.value = TextEditingValue(
      text: _newValue,
      selection: TextSelection.fromPosition(
        TextPosition(offset: _controller.selection.base.offset < _newValue.length ? _controller.selection.base.offset : _newValue.length),
      ),
    );
  }

  void _checkUrl() {
    setState(() { _showDownloadButton = false; });
    bool _validURL = _isYouTubeUrl(sanitizer.trim(_controller.text));
    !_validURL ? setState(() { _validationError = true; }) : setState(() { _validationError = false; });
  }

  bool _isYouTubeUrl(String url) {
    RegExp regExp = RegExp(r'^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?$');
    return regExp.hasMatch(url);
  }

  String? _getYoutubeThumbnail(String url) {
    RegExp regExp = RegExp(r'^((?:https?:)?\/\/)?((?:www|m)\.)?((?:youtube\.com|youtu.be))(\/(?:[\w\-]+\?v=|embed\/|v\/)?)([\w\-]+)(\S+)?$');
    final RegExpMatch? match = regExp.firstMatch(url);

    if(match != null) {
      String? videoId = match.groupCount >= 5 ? match.group(5) : null;
      return videoId != null ? 'https://img.youtube.com/vi/$videoId/0.jpg' : null;
    }

    return null;
  }

  Future<bool> _isValidYoutubeThumbnail(String url) async {
    Uri urlParsed = Uri.parse(url);
    var response = await http.head(Uri.https(urlParsed.authority, urlParsed.path));
    if(response.statusCode == 200) {
      return true;
    }
    return false;
  }

  void _badYoutubeVideoErrorCallback() {
    setState(() {
      _searchDone = false;
      _preDownloadError = true;
      _validationError = true;
      _showDownloadButton = false;
    });
    _showToast(context, "The video does not exist. Is it written ok?");
  }

  void _downloadVideo() {
    setState(() {
      _downloading = true;
    });
    _appFiles.then((filesDirectory) => {
      _downloadDirectory.then((downloadDirectory) => {
        Process.run(p.join(filesDirectory.path, 'bin', 'youtube-dl.exe'), _isAudio ? ['--no-playlist', '-x', '--audio-format mp3' ,'--ffmpeg-location ${p.join(filesDirectory.path, 'bin', 'ffmpeg.exe')}', _controller.text] : ['--no-playlist', '-f mp4', '--youtube-skip-dash-manifest', _controller.text], workingDirectory: downloadDirectory!.path).then((result) {
          setState(() {
            _downloading = false;
          });
          if(result.exitCode == 0) {
            _showToast(context, "Video downloaded");
          } else {
            print(result.stderr);
            _showToast(context, "Error downloading the video");
          }
        })
      })
    });
  }

  void _searchVideo() {
    _isValidYoutubeThumbnail(_getYoutubeThumbnail(_controller.text) ?? '').then((isValid) => {
      if(isValid) {
        setState(() {
          _searchDone = true;
          _thumbnailPath = _getYoutubeThumbnail(_controller.text) ?? '';
          _preDownloadError = false;
          _showDownloadButton = true;
        })
      } else {
        _badYoutubeVideoErrorCallback()
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          if(_searchDone) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                const Center(
                  child: CircularProgressIndicator()
                ),
                Center(
                  child: FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: _thumbnailPath,
                    width: 480,
                    height: 360,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return Image.asset('assets/images/placeholder-480x360.jpg');
                    },
                  ),
                ),
              ],
            ),
          ] else ...[
            Image.asset('assets/images/placeholder-480x360.jpg')
          ],
          const SizedBox(height: 20),
          Row(
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
                          labelText: 'Enter a YouTube URL',
                          errorText: _validationError ? 'Not a valid YouTube URL' : null,
                        ),
                        onChanged: (String input) { _trimInput(input); },
                        autocorrect: false,
                        enabled: _downloading ? false : true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if(!_preDownloadError && _showDownloadButton) ...[
                            Expanded(
                              child: SwitchListTile(
                                value: _isAudio,
                                title: Text(_isAudio ? 'Download as audio' : 'Download as video'),
                                secondary: Icon(_isAudio ? Icons.audiotrack : Icons.video_collection),
                                onChanged: !_downloading ? (value) { setState(() { _isAudio = value; }); } : null,
                              ),
                            ),
                            const SizedBox(width: 15),
                            ElevatedButton.icon(
                              onPressed: !_downloading ? () {  _downloadVideo(); } : null,
                              onLongPress: null,
                              label: const Text('Download'),
                              icon: _downloading ? const SizedBox(child: CircularProgressIndicator(color: Colors.white), height: 15, width: 15,) : const Icon(Icons.file_download),
                            ),
                          ],
                          const SizedBox(width: 20),
                          if(!_validationError) ...[
                            ElevatedButton.icon(
                              onPressed: !_downloading ? () { _searchVideo(); } : null,
                              onLongPress: null,
                              label: const Text('Search'),
                              icon: const Icon(Icons.search),
                            ),
                          ]
                        ],
                      ),
                    ],
                  )
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(),
              )
            ],
          ),
        ],
      )
    );
  }
}