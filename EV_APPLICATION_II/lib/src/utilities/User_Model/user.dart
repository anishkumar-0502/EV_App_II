import 'package:flutter/material.dart';

class UserData extends ChangeNotifier {
  String? username;
  int? userId;

  UserData({this.username, this.userId});

  void updateUserData(String username, int userId) {
    this.username = username;
    this.userId = userId;
    notifyListeners();
  }

  void clearUser() {
    username = null;
    userId = null;
    notifyListeners();
  }
}
