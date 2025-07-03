import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GenericWebScreen extends StatefulWidget {
  final String title;
  final String url;

  const GenericWebScreen({super.key, required this.title, required this.url});

  @override
  State<GenericWebScreen> createState() => _GenericWebScreenState();
}

class _GenericWebScreenState extends State<GenericWebScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
