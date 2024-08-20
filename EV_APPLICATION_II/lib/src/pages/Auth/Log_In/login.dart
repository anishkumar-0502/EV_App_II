// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../utilities/User_Model/user.dart';
import '../../home.dart';
import '../Sign_Up/register.dart';
import '../../../utilities/Alert/alert_banner.dart'; // Import the alert banner

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEmailInteracted = false;
  bool _isPasswordInteracted = false;
  bool _isPasswordVisible = false;
  String? storedUser;
  String? _alertMessage;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateButtonState);
    _passwordController.addListener(_updateButtonState);
    _retrieveUserData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _retrieveUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      storedUser = prefs.getString('user');
    });
  }

  void _updateButtonState() {
    setState(() {});
  }

  bool _validateEmail(String value) {
    final emailRegex = RegExp(r'^[^@]+@gmail\.com$');
    return emailRegex.hasMatch(value);
  }

  bool _isFormValid() {
    final form = _formKey.currentState;
    return form?.validate() ?? false;
  }

  Future<void> _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:9098/profile/CheckLoginCredentials'),
        headers: {'Content-Type': 'application/json'}, // Ensure content type is set
        body: jsonEncode({
          'email_id': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        String username = responseData['data']['username']; // Adjust based on the response structure
        int userId = responseData['data']['user_id']; // Adjust based on the response structure

        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('user', username); // Store username
        prefs.setInt('userId', userId); // Store userId
        Provider.of<UserData>(context, listen: false).updateUserData(username, userId);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HomePage(
              username: username,
              userId: userId,
            ),
          ),
        );
      } else {
        final data = json.decode(response.body);
        _showAlertBanner(data['message']);}
    } catch (e) {
      _showAlertBanner('An error occurred: $e');
    }
  }

  void _showAlertBanner(String message) {
    setState(() {
      _alertMessage = message;
    });
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _alertMessage = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return storedUser != null
        ? HomePage(username: storedUser!) // Navigate to HomePage if user is already logged in
        : Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              elevation: 0,
              toolbarHeight: 0, // Hide the AppBar
            ),
            body: Column(
              children: [
                if (_alertMessage != null)
                  AlertBanner(message: _alertMessage!), // Display the alert banner
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Welcome Back! Sign In to dive in?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Enter your email and password to continue.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(200, 58, 58, 60), // Dark gray color
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Email',
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.emailAddress,
                            cursorColor: const Color(0xFF1ED760), // Cursor color
                            validator: (value) {
                              if (!_isEmailInteracted) return null; // Show error only if interacted
                              if (value == null || value.isEmpty) {
                                return 'Please Enter Email';
                              }
                              if (!_validateEmail(value)) {
                                return 'Enter a valid email address (e.g., username@gmail.com)';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _updateButtonState();
                            },
                            onTap: () {
                              setState(() {
                                _isEmailInteracted = true;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible, // Toggle visibility based on _isPasswordVisible
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(200, 58, 58, 60), // Dark gray color
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Password',
                              hintStyle: const TextStyle(color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible; // Toggle visibility state
                                  });
                                },
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4), // Restrict to 4 digits
                            ],
                            cursorColor: const Color(0xFF1ED760), // Cursor color
                            validator: (value) {
                              if (!_isPasswordInteracted) return null; // Show error only if interacted
                              if (value == null || value.isEmpty) {
                                return 'Please Enter Password';
                              }
                              if (value.length != 4) {
                                return 'Password must be exactly 4 digits';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _updateButtonState();
                            },
                            onTap: () {
                              setState(() {
                                _isPasswordInteracted = true;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isFormValid() ? _login : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFormValid() ? const Color(0xFF1C8B39) : Colors.transparent, // Dark green when enabled
                              minimumSize: const Size(double.infinity, 50), // Set the width to be full width
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              side: BorderSide(
                                color: _isFormValid() ? Colors.transparent : Colors.transparent, // No border color when disabled
                              ),
                              elevation: 0,
                            ).copyWith(
                              backgroundColor: WidgetStateProperty.resolveWith<Color?>(
                                (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.disabled)) {
                                    return Colors.green.withOpacity(0.2); // Light green gradient
                                  }
                                  return const Color(0xFF1C8B40); // Dark green color
                                },
                              ),
                            ),
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _isFormValid() ? Colors.white : Colors.green[700], // Text color for button
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 80,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to Register page
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                                    );
                                  },
                                  child: Text(
                                    'New User? Sign Up!',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    // Navigate to Forgot Password page
                                    // Navigator.push(
                                    //   context,
                                    //   MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                                    // );
                                  },
                                  child: Text(
                                    'Forgot password ?',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
