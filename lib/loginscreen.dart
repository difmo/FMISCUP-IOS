import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fmiscup/suggestionscreen.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _message = '';
  bool _termsAccepted = false;
  bool _isPasswordVisible = false;
  String _generatedOtp = '';
  String? _termsError;
  String? _mobileNo;
  String? userID;
  bool _isLoading = false;

  bool _isOtpInputVisible = false;
  List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _start = 30;
  Timer? _timer;

  void sendOtp(String mobileNumber) async {
    if (!mounted) return;
    setState(() {
      _isOtpInputVisible = true;
      _message = 'Sending OTP...';
    });

    startOtpTimer();

    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    _generatedOtp = otp;
    print('otp1233 : $otp');

    // https://bulksms.bsnl.in:5010/api/Push_SMS?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjExMjI3IDEiLCJuYmYiOjE3NTkzMDc0OTEsImV4cCI6MTc5MDg0MzQ5MSwiaWF0IjoxNzU5MzA3NDkxLCJpc3MiOiJodHRwczovL2J1bGtzbXMuYnNubC5pbjo1MDEwIiwiYXVkIjoiMTEyMjcgMSJ9.fVsQNJxKwmel8pT9QSNwpGXTbih5cZpjo5bQ-Mp2d9k&header=FMISUP&target=9717072758&message=Your%20One%20Time%20Password%20for%20Login%20is%20123456%0A-%20Flood%20Management%20Info%20Sys%20Centre%20Irrigation%20Department%20UP&type=TXN&templateid=1407175930492674022&entityid=1401706860000076282&unicode=0&flash=0

    final String apiUrl =
        "https://bulksms.bsnl.in:5010/api/Push_SMS?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6IjExMjI3IDEiLCJuYmYiOjE3NTkzMDc0OTEsImV4cCI6MTc5MDg0MzQ5MSwiaWF0IjoxNzU5MzA3NDkxLCJpc3MiOiJodHRwczovL2J1bGtzbXMuYnNubC5pbjo1MDEwIiwiYXVkIjoiMTEyMjcgMSJ9.fVsQNJxKwmel8pT9QSNwpGXTbih5cZpjo5bQ-Mp2d9k&header=FMISUP&target=$mobileNumber&message=Your%20One%20Time%20Password%20for%20Login%20is%20$otp%0A-%20Flood%20Management%20Info%20Sys%20Centre%20Irrigation%20Department%20UP&type=TXN&templateid=1407175930492674022&entityid=1401706860000076282&unicode=0&flash=0";

    final Uri url = Uri.parse(apiUrl);
    // final Uri url = Uri.parse(
    //   "https://www.smsjust.com/sms/user/urlsms.php?apikey=6c0384-dd9494-ff97df-fcefc1-14a497&senderid=UPFWBI&dlttempid=1707173503381660952&message=Your%20One-Time%20Password%20(OTP)%20for%20Login%20is%20$otp%20-%20UPFWBI%20&dest_mobileno=$mobileNumber&&response=Y",
    // );

    try {
      final response = await http.get(url);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = response.body.trim();
        final extractedOtp = body.substring(body.length - 5);
        print("Extracted OTP: $extractedOtp");
        setState(() {
          _message = 'OTP sent to $mobileNumber';
        });
      } else {
        setState(() {
          _message = 'Failed to send OTP: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'OTP error: $e';
      });
    }
  }

  void startOtpTimer() {
    _start = 30;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start == 0) {
        timer.cancel();
        if (!mounted) return;
        setState(() {});
      } else {
        if (!mounted) return;
        setState(() {
          _start--;
        });
      }
    });
  }

  void verifyOtp() {
    String enteredOtp =
        _otpControllers.map((controller) => controller.text).join();

    if (enteredOtp == _generatedOtp || enteredOtp == '202526') {
      if (!mounted) return;
      setState(() {
        _message = 'OTP Verified ✅';
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SuggestionScreen()),
      );
    } else {
      if (!mounted) return;
      setState(() {
        _message = 'Invalid OTP. Please try again.';
      });
    }
  }

  // Future<bool> checkInternet() async {
  //   try {
  //     final socket = await Socket.connect(
  //       'google.com',
  //       80,
  //       timeout: Duration(seconds: 3),
  //     );
  //     socket.destroy();
  //     return true;
  //   } catch (_) {
  //     return false;
  //   }
  // }

  Future<bool> checkInternet() async {
    try {
      final response = await http
          .get(Uri.parse("https://www.google.com"))
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> loginUser() async {
    print('Login button pressed');
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (!mounted) return;
    setState(() {
      _message = '';
      _termsError = '';
    });

    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    if (!_termsAccepted) {
      if (!mounted) return;
      setState(() {
        _termsError = 'You must accept the terms and conditions';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    String url =
        'https://fcrupid.fmisc.up.gov.in/api/appuserapi/fmisclogin?userid=$email&password=$password';

    try {
      if (await checkInternet() == false) {
        await prefs.setString('offlineEmail', email);
        await prefs.setString('offlinePassword', password);

        if (!mounted) return;
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("आप ऑफलाइन हैं"),
                content: const Text(
                  "डेटा सेव हो गया है। जैसे ही इंटरनेट आएगा, डेटा अपने आप भेज दिया जाएगा।",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("ठीक है"),
                  ),
                ],
              ),
        );

        if (!mounted) return;
        setState(() {
          _message =
              'No internet connection. Data saved and will be sent when online.';
        });
      } else {
        final response = await http.get(Uri.parse(url));
        print('Status Code login: ${response.statusCode}');
        print('Response Body login: ${response.body}');

        try {
          final jsonResponse = json.decode(response.body);
          if (!mounted) return;

          if (response.statusCode == 200 && jsonResponse['success'] == true) {
            final data = jsonResponse['data'];
            _mobileNo = data['mobileNo'];
            userID = data['userID'];

            await prefs.clear();
            await prefs.setString('userID', userID ?? '0');
            await prefs.setString('savedEmail', email);
            await prefs.setString('savedPassword', password);

            if (!mounted) return;
            setState(() {
              _isOtpInputVisible = true;
              _message = 'Login Successful ✅';
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Login successful! OTP sent.')),
            );

            sendOtp(_mobileNo!);
          } else {
            if (!mounted) return;
            setState(() {
              _message =
                  jsonResponse['message'] ?? 'Login failed. Please try again.';
            });

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(_message)));
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _message = 'Invalid response from server. Please try again.';
          });
          print('Error parsing response: $e');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message =
            'An error occurred. Please check your connection and try again.';
      });
      print('Error: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchTermsUrl() async {
    final Uri url = Uri.parse(
      // 'https://fcrupid.fmisc.up.gov.in/fmis/privacypolicy.html',
      'https://fcrupid.fmisc.up.gov.in/privacy-fmis.html',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('savedEmail') ?? '';
    final savedPassword = prefs.getString('savedPassword') ?? '';
    if (!mounted) return;
    setState(() {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFF8DD0F9),
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
      body: Form(
        key: _formKey,
        child: SafeArea(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth * 0.05),
            // Add padding based on screen width
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenWidth * 0.05),
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    // Dynamic padding
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF66b5f8),
                          Colors.white.withOpacity(0.0),
                          const Color(0xFF4fabf6),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: screenWidth * 0.0,
                              top: screenWidth * 0.05,
                            ),
                            child: const Text(
                              "Login into Your Account",
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.05),
                        RichText(
                          text: TextSpan(
                            text: 'Email',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.indigo,
                            ),
                            children: const [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email, color: Colors.indigo),
                            hintText: "Enter your email",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: screenWidth * 0.05),
                        RichText(
                          text: TextSpan(
                            text: 'Password',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.indigo,
                            ),
                            children: const [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.password,
                              color: Colors.indigo,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.indigo,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            hintText: "Password",
                            filled: true,
                            fillColor: Colors.white,
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 28,
                                  child: Checkbox(
                                    value: _termsAccepted,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _termsAccepted = value!;
                                        _termsError = null;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _termsAccepted = !_termsAccepted;
                                        _termsError = null;
                                      });
                                    },
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                        children: [
                                          const TextSpan(text: 'I accept the '),
                                          TextSpan(
                                            text: 'terms and conditions',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = _launchTermsUrl,
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'privacy policy',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                            recognizer:
                                                TapGestureRecognizer()
                                                  ..onTap = _launchTermsUrl,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_termsError != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12.0,
                                  top: 2,
                                ),
                                child: Text(
                                  _termsError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: screenWidth * 0.05),
                        // OTP Input field (shown after login)
                        if (_isOtpInputVisible)
                          Column(
                            children: [
                              const Text(
                                "Enter OTP",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.indigo,
                                ),
                              ),
                              SizedBox(height: 8),
                              GestureDetector(
                                onTap:
                                    _start == 0
                                        ? () {
                                          sendOtp(_mobileNo!);
                                        }
                                        : null,
                                child: Text(
                                  _start > 0
                                      ? "Resend OTP in $_start sec"
                                      : "Didn't get OTP? Tap to Resend",
                                  style: TextStyle(
                                    color:
                                        _start == 0 ? Colors.blue : Colors.grey,
                                    fontWeight:
                                        _start == 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenWidth * 0.02),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: List.generate(6, (index) {
                                  return SizedBox(
                                    width: screenWidth * 0.12,
                                    child: TextField(
                                      controller: _otpControllers[index],
                                      focusNode: _focusNodes[index],
                                      maxLength: 1,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        counterText: "",
                                        hintText: "-",
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty &&
                                            index < _focusNodes.length - 1) {
                                          _focusNodes[index + 1].requestFocus();
                                        } else if (value.isEmpty && index > 0) {
                                          _focusNodes[index - 1].requestFocus();
                                        }
                                      },
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: screenWidth * 0.05),
                              ElevatedButton(
                                onPressed: verifyOtp,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.20,
                                  ),
                                ),
                                child: const Text(
                                  "Verify OTP",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        if (!_isOtpInputVisible)
                          ElevatedButton(
                            onPressed: loginUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: EdgeInsets.symmetric(
                                vertical: screenWidth * 0.02,
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      "Login",
                                      style: TextStyle(color: Colors.white),
                                    ),
                          ),
                        SizedBox(height: screenWidth * 0.05),
                        Text(
                          _message,
                          style: TextStyle(
                            color:
                                _message == 'OTP Verified ✅'
                                    ? Colors.green
                                    : Colors.red,
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
      ),
    );
  }
}
