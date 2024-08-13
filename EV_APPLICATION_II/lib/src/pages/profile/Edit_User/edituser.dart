import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../../utilities/User_Model/ImageProvider.dart'; // Ensure you have this import

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
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isUsernameInteracted = false;
  bool _isPhoneInteracted = false;
  bool _isOldPasswordInteracted = false;
  bool _isNewPasswordInteracted = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.username;
    _emailController.text = widget.email;
    if (widget.phoneNo != null) {
      _phoneController.text = widget.phoneNo.toString();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  String? _validateUsername(String value) {
    final usernameRegex = RegExp(r'^[a-zA-Z]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Username must be alphabets only';
    }
    return null;
  }

  String? _validatePassword(String? value, {bool isNew = false}) {
    if (value == null || value.isEmpty) {
      return 'Enter your password';
    }
    if (isNew && (value.length != 4 || !RegExp(r'^\d+$').hasMatch(value))) {
      return 'New password must be exactly 4 digits';
    }
    if (!isNew && (value.length > 4 || !RegExp(r'^\d*$').hasMatch(value))) {
      return 'Old password must be up to 4 digits';
    }
    return null;
  }

  void _handleUpdate() async {
    if (widget.userId == null) {
      _showAlertBanner('User ID is required');
      return;
    }

    final int userId = widget.userId!;
    final String username = _usernameController.text;
    final String phone = _phoneController.text;
    final String oldPassword = _oldPasswordController.text;
    final String newPassword = _newPasswordController.text;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:9098/profile/UpdateUserProfile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'username': username,
          'phone_no': phone,
          'current_password': oldPassword,
          'new_password': newPassword,
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
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['error_message'] ?? 'Update failed';
        _showAlertBanner(errorMessage);
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
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userImageProvider = Provider.of<UserImageProvider>(context);

    return Scaffold(
      
      body: Column(
        children: [
          Container(
            color: Colors.black,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          ' Profile',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                CustomGradientDivider(),
              ],
            ),
          ),
  
          Expanded(
            child: SingleChildScrollView(
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
                    const SizedBox(height: 16),
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.green, // Set the border color to green
                                  width: 3.0, // Set the border width
                                ),
                              ),
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
                              return _validateUsername(value ?? '') ?? '';
                            },
                            onChanged: (value) {
                              setState(() {}); // Always enable the button
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
                              fillColor: const Color.fromARGB(200, 58, 58, 60),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Email',
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color(0xFF1ED760),
                            readOnly: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {}); // Always enable the button
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
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (!_isPhoneInteracted) return null;
                              return (value != null && value.isNotEmpty) ? null : 'Phone number is required';
                            },
                            onChanged: (value) {
                              setState(() {}); // Always enable the button
                            },
                            onTap: () {
                              setState(() {
                                _isPhoneInteracted = true;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _oldPasswordController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(200, 58, 58, 60),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Old Password (Optional)',
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color(0xFF1ED760),
                            obscureText: true,
                            validator: (value) {
                              if (!_isOldPasswordInteracted) return null;
                              return _validatePassword(value, isNew: false) ?? '';
                            },
                            onChanged: (value) {
                              setState(() {}); // Always enable the button
                            },
                            onTap: () {
                              setState(() {
                                _isOldPasswordInteracted = true;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(200, 58, 58, 60),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'New Password (Optional)',
                              hintStyle: const TextStyle(color: Colors.grey),
                            ),
                            style: const TextStyle(color: Colors.white),
                            cursorColor: const Color(0xFF1ED760),
                            obscureText: true,
                            validator: (value) {
                              if (!_isNewPasswordInteracted) return null;
                              return _validatePassword(value, isNew: true) ?? '';
                            },
                            onChanged: (value) {
                              setState(() {}); // Always enable the button
                            },
                            onTap: () {
                              setState(() {
                                _isNewPasswordInteracted = true;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          Center(
                          child: CustomGradientButton(
                            buttonText: 'Save Changes',
                            onPressed: _handleUpdate,
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
        ],
      ),
    );
  }
}

class CustomGradientButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;

  const CustomGradientButton({
    Key? key,
    required this.buttonText,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ).copyWith(
        elevation: MaterialStateProperty.all(0),
        backgroundColor: MaterialStateProperty.resolveWith(
              (states) => Colors.transparent,
        ),
      ),
      onPressed: onPressed,
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 200, maxHeight: 50),
          alignment: Alignment.center,
          child: Text(
            buttonText,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class CustomGradientDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1.2, // Adjust this to change the overall height of the divider
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
          Color.fromRGBO(0, 0, 0, 0.75), // Darker black shade
          Color.fromRGBO(0, 128, 0, 0.75), // Darker green for blending
          Colors.green, // Green color in the middle
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
