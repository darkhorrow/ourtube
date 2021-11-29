import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:validators/sanitizers.dart' as sanitizer;
import 'package:http/http.dart' as http;

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
  String _thumbnailPath = '';
  final _controller = TextEditingController();
  FadeInImage? _imageController;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_checkUrl);
  }

  @override
  void dispose() {
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
    });
    _showToast(context, "The video does not exist. Is it written ok?");
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
                  child: _imageController = FadeInImage.memoryNetwork(
                    placeholder: kTransparentImage,
                    image: _thumbnailPath,
                    width: 480,
                    height: 360,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        width: 480,
                        height: 360,
                      );
                    },
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(
              width: 480,
              height: 360,
            )
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
                        ),
                        if(!_preDownloadError) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              label: const Text('Download'),
                              icon: const Icon(Icons.file_download),
                            ),
                          )
                        ],
                        if(!_validationError) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _isValidYoutubeThumbnail(_getYoutubeThumbnail(_controller.text) ?? '').then((isValid) => {
                                  if(isValid) {
                                    setState(() {
                                      _searchDone = true;
                                      _thumbnailPath = _getYoutubeThumbnail(_controller.text) ?? '';
                                      _preDownloadError = false;
                                    })
                                  } else {
                                    _badYoutubeVideoErrorCallback()
                                  }
                                });
                              },
                              label: const Text('Search'),
                              icon: const Icon(Icons.search),
                            ),
                          )
                        ]
                      ],
                    )
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(),
              )
            ],
          )
        ],
      )
    );
  }
}