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
    print("ohooho");
    print(widget.url);
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

    isPdf = extension == '.pdf';

    if (isPdf) {
      final success = await _preparePdf();
      if (success && localPath != null) {
        try {
          pdfController = PdfController(
            document: PdfDocument.openFile(localPath!),
          );
        } catch (e) {
          debugPrint("PDF Controller error: $e");
          // Fallback to WebView
          isPdf = false;
        }
      } else {
        isPdf = false; // Fallback to WebView if invalid PDF
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<bool> _preparePdf() async {
    try {
      final filename = p.basename(widget.url);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');

      final request = await HttpClient().getUrl(Uri.parse(widget.url));
      final response = await request.close();

      final contentLength = response.contentLength; // may be -1
      int received = 0;

      final raf = file.openSync(mode: FileMode.write);
      await for (var chunk in response) {
        raf.writeFromSync(chunk);
        received += chunk.length;

        setState(() {
          // fallback: show percent if known, else just loading spinner
          progress =
              contentLength > 0
                  ? (received / contentLength)
                  : -1; // signal unknown
        });
      }
      await raf.close();

      // Check PDF magic bytes
      final bytes = await file.openRead(0, 4).first;
      if (String.fromCharCodes(bytes) != '%PDF') {
        debugPrint("Downloaded file is NOT a valid PDF.");
        return false;
      }

      localPath = file.path;
      return true;
    } catch (e) {
      debugPrint("Exception in PDF load: $e");
      return false;
    }
  }

  // Future<bool> _isValidPdf(File file) async {
  //   try {
  //     final bytes = await file.openRead(0, 4).first;
  //     return String.fromCharCodes(bytes) == '%PDF';
  //   } catch (_) {
  //     return false;
  //   }
  // }

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
