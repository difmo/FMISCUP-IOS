import 'dart:convert';
import 'dart:io';
import 'package:fmiscup/constants.dart';
import 'package:fmiscup/globalclass.dart';
import 'package:fmiscup/loginscreen.dart';
import 'package:fmiscup/pdfviewerscreen.dart';
import 'package:fmiscup/suggestionscreen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ministercardscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'api_client.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> menuItems = [];

  String _formatTitle(String title) {
    List<String> words = title.split(' ');
    if (words.length <= 1) return title;
    if (words.length == 3) {
      return '${words[0]} ${words[1]}\n${words[2]}';
    }
    int mid = words.length ~/ 2;
    return '${words.sublist(0, mid).join(' ')}\n${words.sublist(mid).join(' ')}';
  }

  @override
  void initState() {
    super.initState();
    sendLocalData();
    fetchMenuItems();
  }

  Future<void> sendLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    String lastSubmittedUserID = prefs.getString('lastSubmittedUserID') ?? "";
    if (lastSubmittedUserID.isNotEmpty) {
      String lastSuggestionText =
          await prefs.getString('lastSuggestionText') ?? "";
      String lastImagePath = await prefs.getString('lastImagePath') ?? "";
      if (await GlobalClass.checkInternet()) {
        sendLocalDataOnServer(
          lastSubmittedUserID,
          lastSuggestionText,
          lastImagePath,
        );
      }
    }
  }

  Future<void> sendLocalDataClear() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('lastSubmittedUserID', "");
    prefs.setString('lastSuggestionText', "");
    prefs.setString('lastImagePath', "");
  }

  Future<File> _compressImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(Uint8List.fromList(imageBytes));
    if (image == null) {
      throw Exception("Image compression failed");
    }
    final compressedImage = img.encodeJpg(image, quality: 85);
    final tempDir = await getTemporaryDirectory();
    final tempPath =
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final compressedFile = File(tempPath)..writeAsBytesSync(compressedImage);
    return compressedFile;
  }

  Future<void> sendLocalDataOnServer(
    String lastSubmittedUserID,
    String lastSuggestionText,
    String lastImagePath,
  ) async {
    try {
      final uri = Uri.parse(
        "https://fcrupid.fmisc.up.gov.in/api/appsuggapi/sappimageupload",
      );

      File? _pickedImage = File(lastImagePath);

      final request = http.MultipartRequest('POST', uri);
      request.fields['ID'] = lastSubmittedUserID;
      request.fields['Suggestion'] = lastSuggestionText;
      request.fields['WorkImage'] = '$_pickedImage';
      final compressedFile = await _compressImage(_pickedImage);
      final fileSize = await compressedFile.length();
      if (fileSize > 4 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image size exceeds 4 MB after compression.'),
          ),
        );
        return;
      }
      request.files.add(
        await http.MultipartFile.fromPath('WorkImage', compressedFile.path),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint("Status Code sappimageupload: ${response.statusCode}");
      debugPrint("Response sappimageupload: ${response.body}");
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("hello sappimageupload: $responseData");
        if (responseData['success'] == true) {
          if (context.mounted) {
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Success'),
                    content: const Text('Suggestion submitted successfully.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          sendLocalDataClear();
                          Navigator.pop(context);
                        },

                        child: const Text('OK'),
                      ),
                    ],
                  ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Submission failed: ${responseData['message']}'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed. Try again later.')),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error occurred: $e')));
    }
  }

  Future<void> fetchMenuItems() async {
    try {
      final response = await ApiClient().get(
        Uri.parse('https://fcrupid.fmisc.up.gov.in/api/appuserapi/webview'),
        headers: {
          'Accept': 'application/json, text/plain, */*',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36',
          'Connection': 'keep-alive',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          if (!mounted) return;
          setState(() {
            menuItems = data['data'];
          });
        }
      } else {
        throw Exception('Failed to load menu items');
      }
    } catch (e) {
      debugPrint("Error fetching menu items: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB2D7F2),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Color(0xFF0047AB),
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Centered text
                Center(
                  child: Text(
                    'FMIS-UP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Left logo
                Positioned(
                  left: 10,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: const CircleAvatar(
                          radius: 20,
                          backgroundImage: AssetImage('assets/image/logo.png'),
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 3),
              // Menu Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child:
                    menuItems.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : LayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount =
                                MediaQuery.of(context).size.width > 600 ? 4 : 3;
                            List<List<dynamic>> rows = [];
                            for (
                              int i = 0;
                              i < menuItems.length;
                              i += crossAxisCount
                            ) {
                              int end = i + crossAxisCount;
                              if (end > menuItems.length) {
                                end = menuItems.length;
                              }
                              rows.add(menuItems.sublist(i, end));
                            }

                            return Column(
                              children:
                                  rows.asMap().entries.map((entry) {
                                    int rowIndex = entry.key;
                                    List<dynamic> rowItems = entry.value;

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            rowIndex == rows.length - 1
                                                ? 0
                                                : 10,
                                      ),
                                      child: IntrinsicHeight(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: List.generate(
                                            crossAxisCount,
                                            (colIndex) {
                                              Widget childWidget;
                                              if (colIndex < rowItems.length) {
                                                childWidget = buildMenuItem(
                                                  context,
                                                  rowItems[colIndex],
                                                );
                                              } else {
                                                childWidget =
                                                    const SizedBox.shrink();
                                              }

                                              return Expanded(
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    left: colIndex == 0 ? 0 : 5,
                                                    right:
                                                        colIndex ==
                                                                crossAxisCount -
                                                                    1
                                                            ? 0
                                                            : 5,
                                                  ),
                                                  child: childWidget,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            );
                          },
                        ),
              ),
              const SizedBox(height: 7),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFCCE5FF)],
                  ),
                  border: Border.all(color: Colors.blue.shade900, width: 3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SuggestionScreen(),
                      ),
                    );
                  },
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/image/suggestion.png',
                          width: 24,
                          height: 24,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          "Suggestion",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 7),
              // Ministers Heading
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0047AB),
                    border: Border.all(
                      color: const Color(0xFF0047AB),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Center(
                    child: Text(
                      "Hon'ble Ministers",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              //  const SizedBox(height: 10), // Ministers Cards using Wrap
              Padding(
                padding: const EdgeInsets.all(10),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double screenWidth = constraints.maxWidth;

                    int crossAxisCount;
                    if (screenWidth < 600) {
                      crossAxisCount = 2;
                    } else if (screenWidth < 900) {
                      crossAxisCount = 3;
                    } else {
                      crossAxisCount = 4;
                    }

                    List<List<Map<String, String>>> rows = [];
                    for (
                      int i = 0;
                      i < Constants.ministers.length;
                      i += crossAxisCount
                    ) {
                      int end = i + crossAxisCount;
                      if (end > Constants.ministers.length) {
                        end = Constants.ministers.length;
                      }
                      rows.add(Constants.ministers.sublist(i, end));
                    }

                    return Column(
                      children:
                          rows.asMap().entries.map((entry) {
                            int rowIndex = entry.key;
                            List<Map<String, String>> rowItems = entry.value;

                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: rowIndex == rows.length - 1 ? 0 : 12,
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: List.generate(crossAxisCount, (
                                    colIndex,
                                  ) {
                                    Widget childWidget;
                                    if (colIndex < rowItems.length) {
                                      final minister = rowItems[colIndex];
                                      final isWideImage =
                                          minister['name'] == 'Yogi Adityanath';
                                      childWidget = MinisterCard(
                                        name: minister['name']!,
                                        position: minister['position']!,
                                        imagePath: minister['imagePath']!,
                                        isWideImage: isWideImage,
                                      );
                                    } else {
                                      childWidget = const SizedBox.shrink();
                                    }

                                    return Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: colIndex == 0 ? 0 : 6,
                                          right:
                                              colIndex == crossAxisCount - 1
                                                  ? 0
                                                  : 6,
                                        ),
                                        child: childWidget,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildMenuItem(BuildContext context, Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        final String title = item['title'];
        final String url = item['webURL'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SmartFileViewer(title: title, url: url),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFCCE5FF)],
          ),
          border: Border.all(color: Colors.blue.shade900, width: 2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              item['imageURL'],
              height: 60,
              width: 60,
              errorBuilder:
                  (_, __, ___) => const Icon(Icons.image_not_supported),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _formatTitle(item['title']),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
