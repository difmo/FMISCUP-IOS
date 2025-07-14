import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dashboardscreen.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key});

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  final TextEditingController _suggestionController = TextEditingController();
  File? _pickedImage;

  String imagePathGlobal = "";
  bool _isSubmitting = false;
  String? userID;

  @override
  void initState() {
    super.initState();
    _loadUserID();
  }

  Future<void> _loadUserID() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userID = prefs.getString('userID'); // ✅ Get userID
    });
    print('Retrieved User ID: $userID');
  }

  Future<File?> _takePhoto() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          'custom_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String customPath = path.join(appDir.path, fileName);

      File originalFile = File(pickedFile.path);
      int fileSize = await originalFile.length();

      // Check if file is already under 4 MB
      if (fileSize <= 4 * 1024 * 1024) {
        final File newImage = await originalFile.copy(customPath);
        return newImage;
      }

      // Compress the image if it's larger than 4 MB
      final String compressedPath = path.join(
        appDir.path,
        'compressed_$fileName',
      );
      final XFile? compressedFile =
          (await FlutterImageCompress.compressAndGetFile(
            originalFile.path,
            compressedPath,
            quality: 70, // You can adjust quality for better size control
          ));
      File file = File(compressedFile?.path ?? "");
      if (await file.length() <= 4 * 1024 * 1024) {
        return file;
      } else {
        // If still too big, return null or handle accordingly
        print('Image is too large even after compression.');
        return null;
      }
    }
    return null;
  }

  Future<void> _pickImageFromCamera(BuildContext context) async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.camera,
        );
        if (pickedFile != null) {
          final imageFile = File(pickedFile.path);
          setState(() {
            _pickedImage = imageFile;
          });
          // Now send to server as Multipart (IFormFile-compatible)
          //   await _submitSuggestion(imageFile,context );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Camera error: $e")));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
    }
  }

  void _handlePhotoCapture() async {
    try {
      final File? imagePath = await _takePhoto();
      if (imagePath != null) {
        setState(() {
          _pickedImage = imagePath;
        });
      } else {
        print('No photo captured.');
      }
    } catch (e) {
      e.toString();
    }
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

  Future<bool> checkInternet() async {
    try {
      final socket = await Socket.connect(
        'google.com',
        80,
        timeout: Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _submitSuggestion(BuildContext context) async {
    final suggestion = _suggestionController.text.trim();
    if (suggestion.isEmpty && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a suggestion or upload an image.'),
        ),
      );
      return;
    }
    if (suggestion.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suggestion cannot exceed 500 characters.'),
        ),
      );
      return;
    }

    if (await checkInternet()) {
      setState(() {
        _isSubmitting = true;
      });
      try {
        final uri = Uri.parse(
          "https://fcrupid.fmisc.up.gov.in/api/appsuggapi/sappimageupload",
        );
        final request = http.MultipartRequest('POST', uri);
        request.fields['ID'] = userID!;
        request.fields['Suggestion'] =
            suggestion.isNotEmpty ? suggestion : 'desc';
        request.fields['WorkImage'] = '$_pickedImage';

        print('userID : $userID');
        if (_pickedImage != null) {
          final compressedFile = await _compressImage(_pickedImage!);
          final fileSize = await compressedFile.length();
          if (fileSize > 4 * 1024 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image size exceeds 4 MB after compression.'),
              ),
            );
            setState(() {
              _isSubmitting = false;
            });
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
              showDD('Suggestion submitted successfully.');
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
            const SnackBar(
              content: Text('Submission failed. Try again later.'),
            ),
          );
        }
      } catch (e) {
        debugPrint("Error: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error occurred: $e')));
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastSubmittedUserID', userID!);
      await prefs.setString(
        'lastSuggestionText',
        suggestion.isNotEmpty ? suggestion : 'desc',
      );
      if (_pickedImage != null) {
        await prefs.setString('lastImagePath', _pickedImage!.path);
        showDD('Suggestion Locally submitted successfully.');
      }
    }
  }

  void showDD(String text) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(text),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void showLoaderDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                strokeWidth: 4.0,
              ),
              const SizedBox(height: 10),
              const Text(
                'Uploading...',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context); // Go back
                        },
                      ),
                      const SizedBox(width: 5),
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage('assets/image/logo.png'),
                        backgroundColor: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suggestion Box *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _suggestionController,
                maxLines: null,
                maxLength: 500,
                expands: true,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Write your suggestion here....',
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handlePhotoCapture(),
                  icon: Icon(Icons.camera_alt, color: Colors.white),
                  label: Text(
                    'Upload Image',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0056A4),
                  ),
                ),
                const SizedBox(width: 20),
                if (_pickedImage != null)
                  Image.file(
                    _pickedImage!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isSubmitting ? null : () => _submitSuggestion(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                  ),
                  child:
                      _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Submit',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
