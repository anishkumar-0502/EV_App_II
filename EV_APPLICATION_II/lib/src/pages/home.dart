// home_page.dart
import 'package:flutter/material.dart';
import 'Home_contents/home_content.dart'; // Import the HomeContent file
import '../components/footer.dart';
import 'wallet/wallet.dart';
import 'history/history.dart';
import 'profile/profile.dart';

class HomePage extends StatefulWidget {
  final String username;
  final int? userId;

  const HomePage({super.key, required this.username, this.userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pageIndex = 0;
  final GlobalKey<FooterState> _footerKey = GlobalKey();

  void _onTabChanged(int index) {
    setState(() {
      _pageIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _pageOptions = [
      HomeContent(username: widget.username, userId: widget.userId),
      WalletPage(username: widget.username, userId: widget.userId),
      HistoryPage(username: widget.username, userId: widget.userId),
      ProfilePage(username: widget.username, userId: widget.userId),
    ];

    return WillPopScope(
      onWillPop: () async {
        final footerState = _footerKey.currentState;
        if (footerState != null) {
          return footerState.handleBackPress();
        } 
        return true;
      },
      child: Scaffold(
        body: _pageOptions[_pageIndex],
        bottomNavigationBar: Footer(
          key: _footerKey,
          onTabChanged: _onTabChanged,
        ),
      ),
    );
  }
}
