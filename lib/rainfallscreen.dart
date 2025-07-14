import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RainfallScreen extends StatefulWidget {
  final String url;

  const RainfallScreen({super.key, required this.url});

  @override
  State<RainfallScreen> createState() => _RainfallScreenState();
}

class _RainfallScreenState extends State<RainfallScreen> {
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
        title: const Text('Rainfall Bulletin'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
