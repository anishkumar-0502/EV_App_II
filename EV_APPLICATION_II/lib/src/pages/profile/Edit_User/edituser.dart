import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../utilities/User_Model/ImageProvider.dart';

class EditUserModal extends StatefulWidget {
  final String username;
  final String email;
  final int? phoneNo;
  final String? password;
  final int? userId;

  const EditUserModal({
    super.key,
    required this.username,
    required this.email,
    this.phoneNo,
    this.password,
    this.userId,
  });

  @override
  State<EditUserModal> createState() => _EditUserModalState();
}

class _EditUserModalState extends State<EditUserModal> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isButtonEnabled = false;
  bool _isUsernameInteracted = false;
  bool _isPhoneInteracted = false;
  bool _isPasswordInteracted = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.username;
    _emailController.text = widget.email;

    if (widget.phoneNo != null) {
      _phoneController.text = widget.phoneNo.toString();
    }

    // Load the user image from the provider
    final userImageProvider = Provider.of<UserImageProvider>(context, listen: false);
    userImageProvider.loadImage();
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

  bool _validateUsername(String value) {
    final usernameRegex = RegExp(r'^[a-zA-Z]+$');
    return usernameRegex.hasMatch(value);
  }

  void _handleUpdate() async {
    final String username = _usernameController.text;
    final String phone = _phoneController.text;
    final String password = _passwordController.text;

    if (widget.userId == null) {
      _showAlertBanner('User ID is required');
      return;
    }

    final int userId = widget.userId!;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:9098/profile/UpdateUserProfile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'username': username,
          'phone_no': phone,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.fromLTRB(20, 80, 20, 0),
          ),
        );
        Navigator.pop(context, 'refresh');
      } else {
        _showAlertBanner('Update failed');
      }
    } catch (e) {
      _showAlertBanner('An error occurred: $e');
    }
  }

  void _showAlertBanner(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final userImageProvider = Provider.of<UserImageProvider>(context, listen: false);
      userImageProvider.setImage(File(pickedFile.path));
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userImageProvider = Provider.of<UserImageProvider>(context);

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            CustomGradientDivider(),
            const SizedBox(height: 16),
            Stack(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: userImageProvider.userImage != null
                        ? FileImage(userImageProvider.userImage!)
                        : null,
                    child: userImageProvider.userImage == null
                        ? const Icon(Icons.camera_alt, color: Colors.white, size: 50)
                        : null,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: const CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.edit, color: Colors.black, size: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(200, 58, 58, 60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Username',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white),
                    cursorColor: const Color(0xFF1ED760),
                    validator: (value) {
                      if (!_isUsernameInteracted) return null;
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
                    readOnly: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(150, 100, 100, 100),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Email',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white),
                    cursorColor: const Color(0xFF1ED760),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(200, 58, 58, 60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Password',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white),
                    cursorColor: const Color(0xFF1ED760),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(4),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (!_isPasswordInteracted) return null;
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
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color.fromARGB(200, 58, 58, 60),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'Phone Number',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(color: Colors.white),
                    cursorColor: const Color(0xFF1ED760),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (!_isPhoneInteracted) return null;
                      if (value == null || value.isEmpty) {
                        return 'Enter your phone number';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _validateAndUpdate();
                    },
                    onTap: () {
                      setState(() {
                        _isPhoneInteracted = true;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isButtonEnabled ? _handleUpdate : null,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                          if (!states.contains(MaterialState.disabled)) {
                            return Colors.green[800];
                          }
                          return Colors.green.withOpacity(0.5);
                        },
                      ),
                      foregroundColor: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                          if (!states.contains(MaterialState.disabled)) {
                            return Colors.white;
                          }
                          return Colors.grey;
                        },
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class CustomGradientDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1.2,
      child: CustomPaint(
        painter: GradientPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class GradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        colors: [
          Color.fromRGBO(0, 0, 0, 0.75),
          Color.fromRGBO(0, 128, 0, 0.75),
          Colors.green,
        ],
        end: Alignment.center,
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.0)
      ..quadraticBezierTo(size.width / 3, 0, size.width, size.height * 0.99)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
