import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SmartFileViewer extends StatefulWidget {
  final String url;
  final String title;

  const SmartFileViewer({Key? key, required this.url, required this.title})
    : super(key: key);

  @override
  State<SmartFileViewer> createState() => _SmartFileViewerState();
}

class _SmartFileViewerState extends State<SmartFileViewer> {
  String? localPath;
  bool isPdf = false;
  bool isLoading = true;
  double progress = 0.0;
  PdfController? pdfController;

  @override
  void initState() {
    super.initState();
    _detectFileTypeAndLoad();
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }

  Future<void> _detectFileTypeAndLoad() async {
    final uri = Uri.parse(widget.url);
    final extension = p.extension(uri.path).toLowerCase();

    if (extension == '.pdf') {
      isPdf = true;
      await _preparePdf();
      if (localPath != null) {
        pdfController = PdfController(
          document: PdfDocument.openFile(localPath!),
        );
      }
    } else {
      isPdf = false;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _preparePdf() async {
    final filename = p.basename(widget.url);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');

    if (await file.exists()) {
      setState(() {
        localPath = file.path;
        isLoading = false;
      });
    } else {
      try {
        final request = await HttpClient().getUrl(Uri.parse(widget.url));
        final response = await request.close();

        final totalBytes = response.contentLength ?? 0;
        int bytesReceived = 0;
        final raf = file.openSync(mode: FileMode.write);

        await for (var chunk in response) {
          bytesReceived += chunk.length;
          raf.writeFromSync(chunk);
          setState(() {
            progress = totalBytes > 0 ? (bytesReceived / totalBytes) : 0;
          });
        }

        await raf.close();

        setState(() {
          localPath = file.path;
          isLoading = false;
        });
      } catch (e) {
        debugPrint("Failed to load PDF: $e");
        setState(() {
          isLoading = false;
          localPath = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body:
          isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    if (isPdf)
                      Text(
                        'Loading PDF: ${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 16),
                      )
                    else
                      const Text(
                        'Loading page...',
                        style: TextStyle(fontSize: 16),
                      ),
                  ],
                ),
              )
              : isPdf
              ? (pdfController != null
                  ? PdfView(
                    controller: pdfController!,
                    scrollDirection: Axis.vertical,
                  )
                  : const Center(child: Text("Failed to load PDF")))
              : WebViewWidget(
                controller:
                    WebViewController()
                      ..setJavaScriptMode(JavaScriptMode.unrestricted)
                      ..loadRequest(Uri.parse(widget.url)),
              ),
    );
  }
}
