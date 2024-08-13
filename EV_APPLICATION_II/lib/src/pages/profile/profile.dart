import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../Auth/Log_In/login.dart';
import 'package:ev_app/src/utilities/User_Model/user.dart';
import 'Help/help.dart'; // Import your HelpPage
import 'Edit_User/edituser.dart'; // Import your EditUserModal
import '../../utilities/User_Model/ImageProvider.dart'; // Import the UserImageProvider
import 'Terms_&_Condition/tc.dart'; // Import your TermsPage
import 'Privacy_&_Policy/pp.dart'; // Import your PrivacyPolicyPage
import 'Account/Account.dart';

class ProfilePage extends StatefulWidget {
  final String username;
  final int? userId;

  const ProfilePage({super.key, required this.username, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? email;
  int? phoneNo;
  String? password;
  int _selectedTileIndex = -1; // Index of the selected tile

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    final userImageProvider = Provider.of<UserImageProvider>(context, listen: false);
    userImageProvider.loadImage(); // Load user image when the profile page is initialized
  }

  Future<void> fetchUserDetails() async {
    String? username = widget.username;
    int? user_id = widget.userId;

    print('Fetching user details for user: $username, $user_id');

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:9098/profile/FetchUserProfile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': user_id}),
      );
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        setState(() {
          email = data['data']['email_id'].toString();
          phoneNo = data['data']['phone_no'] is int
              ? data['data']['phone_no']
              : int.tryParse(data['data']['phone_no'].toString());
          password = data['data']['password']; // Store the hashed password
          print(password);
        });
      } else {
        throw Exception('Error fetching user details');
      }
    } catch (error) {
      print('Error fetching user details: $error');
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');

    Provider.of<UserData>(context, listen: false).clearUser();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
          (route) => false,
    );
  }

  void _showEditUserModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.black,
      builder: (BuildContext context) {
        
        return Container(
          height: MediaQuery.of(context).size.height * 0.8, 
          child:  EditUserModal(
            username: widget.username,
            email: email ?? '',
            phoneNo: phoneNo,
            userId: widget.userId,
            password: password,
          ),
        );
      },
    ).then((result) {
    //   // Check if result is 'refresh' to trigger data fetch
      if (result == 'refresh') {
        fetchUserDetails();
        final userImageProvider = Provider.of<UserImageProvider>(context, listen: false);
        userImageProvider.loadImage(); // Reload user image when the modal is closed
      }
    });
  }

  void _showHelpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7, // Set height to 70% of the screen
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: HelpPage(), // Ensure this is the correct widget name
          ),
        );
      },
    );
  }

  void _showAccountModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9, // Set height to 70% of the screen
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: AccountPage(username: widget.username), // Ensure this is the correct widget name
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userImageProvider = Provider.of<UserImageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              ClipPath(
                clipper: CustomClipPath(),
                child: Container(
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade800.withOpacity(0), Colors.black],
                      begin: Alignment.topRight,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(0),
                      bottomRight: Radius.circular(0),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: userImageProvider.userImage != null
                            ? FileImage(userImageProvider.userImage!)
                            : const AssetImage('assets/Image/avatar.png') as ImageProvider,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.username,
                        style: const TextStyle(fontSize: 23, color: Colors.white),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email ?? '',
                        style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 2,
                                color: Colors.green,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [Colors.green.withOpacity(0.1), Colors.transparent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _showEditUserModal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white, // Make the text color white
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                shadowColor: Colors.transparent,
                                minimumSize: const Size(140, 50), // Ensure both buttons have the same size
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, size: 16, color: Colors.white), // Make the icon color white
                                  SizedBox(width: 8),
                                  Text('Edit profile', style: TextStyle(color: Colors.white, fontSize: 14)), // Make the text color white
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 2,
                                color: Colors.red,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [Colors.red.withOpacity(0.1), Colors.transparent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _logout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white, // Make the text color white
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                shadowColor: Colors.transparent,
                                minimumSize: const Size(140, 50), // Ensure both buttons have the same size
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.logout, color: Colors.white, size: 16), // Make the icon color white
                                  SizedBox(width: 8),
                                  Text('Logout', style: TextStyle(color: Colors.white, fontSize: 14)), // Make the text color white
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),


                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    Container(

                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTileIndex = 0;
                              });
                              _showAccountModal();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              color: _selectedTileIndex == 0
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.black,
                              child: ListTile(
                                title: const Text('Account', style: TextStyle(color: Colors.white)),
                                leading: const Icon(Icons.account_circle, color: Colors.white),
                                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTileIndex = 1;
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>  TermsPage(), // Ensure this is the correct widget name
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              color: _selectedTileIndex == 1
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.black,
                              child: ListTile(
                                title: const Text('Terms and Conditions', style: TextStyle(color: Colors.white)),
                                leading: const Icon(Icons.description, color: Colors.white),
                                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTileIndex = 2;
                              });
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>  PrivacyPolicyPage(), // Ensure this is the correct widget name
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              color: _selectedTileIndex == 2
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.black,
                              child: ListTile(
                                title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
                                leading: const Icon(Icons.policy, color: Colors.white),
                                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 35,
            right: 20,
            child: GestureDetector(
              onTap: _showHelpModal ,
              child: const Icon(Icons.help_outline, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomClipPath extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
