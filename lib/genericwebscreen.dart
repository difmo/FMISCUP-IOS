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
  final String pdfUrl =
      'https://fmisc.up.gov.in/advisory/advisory2025/embankmentadvisory-2025.pdf';

  @override
  void initState() {
    super.initState();
    final String viewerUrl =
        'https://docs.google.com/gview?embedded=true&url=$pdfUrl';
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(viewerUrl));
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
