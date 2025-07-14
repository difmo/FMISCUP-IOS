import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

Future<String?> saveVideoFromUrls(
  String url,
  String fileName,
  BuildContext context,
) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } else {
      return null;
    }
  } catch (e) {
    print('Error saving video: $e');
    return null;
  }
}
