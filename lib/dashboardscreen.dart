import 'dart:convert';
import 'dart:io';
import 'package:fmiscup/globalclass.dart';
import 'package:fmiscup/loginscreen.dart';
import 'package:fmiscup/pdfviewerscreen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'genericwebscreen.dart';
import 'ministercardscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> menuItems = [];

  final ministers = [
    {
      'name': 'Yogi Adityanath',
      'position': 'Hon\'ble Chief Minister\nUttar Pradesh',
      'imagePath': 'assets/image/yogi.jpg',
    },
    {
      'name': 'Shri Swatantra Dev Singh',
      'position': 'Hon\'ble Cabinet Minister\nJai Shakti, Uttar Pradesh',
      'imagePath': 'assets/image/swatantra.jpg',
    },
    {
      'name': 'Shri Dinesh Khateek',
      'position': 'Hon\'ble Minister of State\nJai Shakti, Uttar Pradesh',
      'imagePath': 'assets/image/dinesh.jpg',
    },
    {
      'name': 'Shri Ramkesh Nishad',
      'position': 'Hon\'ble Minister of State\nJai Shakti, Uttar Pradesh',
      'imagePath': 'assets/image/ramkesh.jpg',
    },
  ];

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
      if (_pickedImage != null) {
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
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      debugPrint("Status Code sappimageupload: ${response.statusCode}");
      debugPrint("Response sappimageupload: ${response.body}");
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
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
    final response = await http.get(
      Uri.parse('https://fcrupid.fmisc.up.gov.in/api/appuserapi/webview'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          menuItems = data['data'];
        });
      }
    } else {
      throw Exception('Failed to load menu items');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
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
                      // IconButton(
                      //   icon: const Icon(Icons.arrow_back, color: Colors.white),
                      //   onPressed: () {
                      //     Navigator.pop(context); // Go back
                      //   },
                      // ),
                      // const SizedBox(width: 5),
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
              // Top Bar
              // Container(
              //   color: Colors.blue.shade800,
              //   padding: const EdgeInsets.symmetric(
              //       vertical: 5, horizontal: 16),
              //   child: Row(
              //     children: const [
              //       CircleAvatar(
              //         radius: 19,
              //         backgroundImage: AssetImage('assets/image/logo.png'),
              //         backgroundColor: Colors.white,
              //       ),
              //       SizedBox(width: 12),
              //       Text(
              //         'FMISC-UP',
              //         style: TextStyle(
              //           color: Colors.white,
              //           fontSize: 22,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 3),
              // Menu Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child:
                    menuItems.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : GridView.count(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 600 ? 4 : 3,
                          // Responsive grid for larger screens
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children:
                              menuItems
                                  .map((item) => buildMenuItem(context, item))
                                  .toList(),
                        ),
              ),
              const SizedBox(height: 7),
              // Suggestion Box
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
                      MaterialPageRoute(builder: (context) => LoginScreen()),
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
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ministers.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth < 600 ? 2 : 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 4.6 / 4,
                  ),
                  itemBuilder: (context, index) {
                    final minister = ministers[index];
                    final isWideImage = minister['name'] == 'Yogi Adityanath';
                    return MinisterCard(
                      name: minister['name']!,
                      position: minister['position']!,
                      imagePath: minister['imagePath']!,
                      isWideImage: isWideImage,
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
        if (title == "Rainfall Bulletin") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerFromUrl(title: title, url: url),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GenericWebScreen(title: title, url: url),
            ),
          );
        }
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
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item['title'],
                textAlign: TextAlign.center,
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

  void _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $urlString';
    }
  }
}
