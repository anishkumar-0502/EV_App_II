import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:http/http.dart' as http;
import '../Log_In/login.dart';
import '../../../utilities/Alert/alert_banner.dart'; // Import the alert banner

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isButtonEnabled = false;
  bool _isUsernameInteracted = false;
  bool _isEmailInteracted = false;
  bool _isPhoneInteracted = false;
  bool _isPasswordInteracted = false;
  bool _isPasswordVisible = false;
  String? _alertMessage;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_validateAndUpdate);
    _emailController.addListener(_validateAndUpdate);
    _phoneController.addListener(_validateAndUpdate);
    _passwordController.addListener(_validateAndUpdate);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateAndUpdate() {
    setState(() {
      _isButtonEnabled = _formKey.currentState?.validate() ?? false;
    });
  }

  bool _validateEmail(String value) {
    final emailRegex = RegExp(r'^[^@]+@gmail\.com$');
    return emailRegex.hasMatch(value);
  }

  bool _validateUsername(String value) {
    final usernameRegex = RegExp(r'^[a-zA-Z]+$');
    return usernameRegex.hasMatch(value);
  }

  void _handleRegister() async {
    final String username = _usernameController.text;
    final String email = _emailController.text;
    final String phone = _phoneController.text;
    final String password = _passwordController.text;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:9098/profile/RegisterNewUser'),
        headers: {'Content-Type': 'application/json'}, // Ensure content type is set
        body: jsonEncode({
          'username': username,
          'email_id': email,
          'phone_no': phone,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        // Handle successful registration
        Navigator.pop(context); // Assuming you want to pop back after registration
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        toolbarHeight: 0, // Hide the AppBar
      ),
      body: Column(
        children: [
          if (_alertMessage != null)
            AlertBanner(message: _alertMessage!),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Create your Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Fill in the details below to get started.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color.fromARGB(200, 58, 58, 60), // Dark gray color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Username',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color(0xFF1ED760), // Cursor color
                      validator: (value) {
                        if (!_isUsernameInteracted) return null; // Show error only if interacted
                        if (value == null || value.isEmpty) {
                          return 'Enter your username';
                        }
                        if (!_validateUsername(value)) {
                          return 'Username must be alphabets only';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _validateAndUpdate();
                      },
                      onTap: () {
                        setState(() {
                          _isUsernameInteracted = true;
                        });
                      },
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
                          return 'Enter your email';
                        }
                        if (!_validateEmail(value)) {
                          return 'Enter a valid email address (e.g., username@gmail.com)';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _validateAndUpdate();
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
                      obscureText: !_isPasswordVisible, // Control password visibility
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
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color(0xFF1ED760), // Cursor color
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(4), // Limit to 4 digits
                        FilteringTextInputFormatter.digitsOnly, // Only digits allowed
                      ],
                      validator: (value) {
                        if (!_isPasswordInteracted) return null; // Show error only if interacted
                        if (value == null || value.isEmpty) {
                          return 'Enter your password';
                        }
                        if (value.length != 4) {
                          return 'Password must be exactly 4 digits';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _validateAndUpdate();
                      },
                      onTap: () {
                        setState(() {
                          _isPasswordInteracted = true;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    IntlPhoneField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color.fromARGB(200, 58, 58, 60), // Dark gray color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Phone Number',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixStyle: const TextStyle(color: Colors.white), // Change the country code text color
                      ),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color(0xFF1ED760), // Cursor color
                      initialCountryCode: 'IN',
                      onChanged: (phone) {
                        _validateAndUpdate();
                      },
                      onTap: () {
                        setState(() {
                          _isPhoneInteracted = true;
                        });
                      },
                      validator: (phone) {
                        if (!_isPhoneInteracted) return null; // Show error only if interacted
                        if (phone == null || phone.number.isEmpty) {
                          return 'Enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isButtonEnabled ? _handleRegister : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isButtonEnabled ? const Color(0xFF1C8B39) : Colors.transparent, // Dark green when enabled
                        minimumSize: const Size(double.infinity, 50), // Set the width to be full width
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: _isButtonEnabled ? Colors.transparent : Colors.transparent, // No border color when disabled
                        ),
                        elevation: 0,
                      ).copyWith(
                        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.disabled)) {
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
                          color: _isButtonEnabled ? Colors.white : Colors.green[700], // Text color for button
                        ),
                      ),
                    ),
                    const SizedBox(height: 20), // Add space between button and text link
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: Text(
                          'Already a user? Sign In ?',
                          style: TextStyle(fontSize: 15, color: Colors.green[700]),
                        ),
                      ),
                    ),
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
