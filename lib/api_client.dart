import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart'; // for ByteStream

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  final http.Client _client = http.Client();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  Future<http.StreamedResponse> sendMultipartRequest(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
  }) async {
    _logRequest(
      '$method (Multipart)',
      url,
      headers: headers,
      body: fields,
      files: files,
    ); // Log fields as body for visibility

    try {
      var request = http.MultipartRequest(method, url);
      if (headers != null) {
        request.headers.addAll(headers);
      }
      if (fields != null) {
        request.fields.addAll(fields);
      }
      if (files != null) {
        request.files.addAll(files);
      }

      final streamedResponse = await _client.send(request);
      final responseBody = await streamedResponse.stream.bytesToString();

      final httpResponse = http.Response(
        responseBody,
        streamedResponse.statusCode,
        request: request,
        headers: streamedResponse.headers,
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
      );

      _logResponse('$method (Multipart)', url, httpResponse);
      return http.StreamedResponse(
        ByteStream.fromBytes(utf8.encode(responseBody)),
        streamedResponse.statusCode,
        contentLength: streamedResponse.contentLength,
        request: streamedResponse.request,
        headers: streamedResponse.headers,
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
      );
    } catch (e) {
      _logError('$method (Multipart)', url, e);
      rethrow;
    }
  }

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    _logRequest('GET', url, headers: headers);
    try {
      final response = await _client.get(url, headers: headers);
      _logResponse('GET', url, response);
      return response;
    } catch (e) {
      _logError('GET', url, e);
      rethrow;
    }
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    _logRequest('POST', url, headers: headers, body: body);
    try {
      final response = await _client.post(url, headers: headers, body: body);
      _logResponse('POST', url, response);
      return response;
    } catch (e) {
      _logError('POST', url, e);
      rethrow;
    }
  }

  void _logRequest(
    String method,
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    List<http.MultipartFile>? files,
  }) {
    final logData = <String, dynamic>{
      'type': '➡️ REQUEST',
      'method': method,
      'url': url.toString(),
    };

    if (headers != null) {
      logData['headers'] = headers;
    }

    if (body != null) {
      if (body is String) {
        try {
          final jsonBody = json.decode(body);
          logData['body'] = jsonBody;
        } catch (e) {
          logData['body'] = body;
        }
      } else {
        logData['body'] = body;
      }
    }

    if (files != null && files.isNotEmpty) {
      logData['files'] =
          files
              .map(
                (f) => {
                  'field': f.field,
                  'filename': f.filename,
                  'contentType': f.contentType.toString(),
                  'length': f.length,
                },
              )
              .toList();
    }

    print('------------------------------------------------------------------');
    print(_prettyJson(logData));
    print('------------------------------------------------------------------');
  }

  void _logResponse(String method, Uri url, http.Response response) {
    final logData = <String, dynamic>{
      'type': '⬅️ RESPONSE',
      'method': method,
      'url': url.toString(),
      'status': response.statusCode,
    };

    try {
      final dynamic jsonBody = json.decode(response.body);
      logData['body'] = jsonBody;
    } catch (e) {
      logData['body'] = response.body;
    }

    print('------------------------------------------------------------------');
    print(_prettyJson(logData));
    print('------------------------------------------------------------------');
  }

  void _logError(String method, Uri url, Object error) {
    final logData = <String, dynamic>{
      'type': '❌ ERROR',
      'method': method,
      'url': url.toString(),
      'details': error.toString(),
    };

    print('------------------------------------------------------------------');
    print(_prettyJson(logData));
    print('------------------------------------------------------------------');
  }

  String _prettyJson(dynamic jsonObject) {
    var encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(jsonObject);
  }
}
