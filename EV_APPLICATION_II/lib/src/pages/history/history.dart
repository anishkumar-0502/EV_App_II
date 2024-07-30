import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart'; // Import the shimmer package
import '../../utilities/Seperater/gradientPainter.dart';

class HistoryPage extends StatefulWidget {
  final String? username;
  final int? userId;

  const HistoryPage({super.key, this.username, this.userId});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String activeTab = 'history'; // Initial active tab
  List<Map<String, dynamic>> sessionDetails = [];
  bool isLoading = true; // Add loading state

  @override
  void initState() {
    super.initState();
    fetchChargingSessionDetails();
  }

  // Function to set session details
  void setSessionDetails(List<Map<String, dynamic>> value) {
    setState(() {
      sessionDetails = value;
      isLoading = false; // Set loading state to false after fetching data
    });
  }

  // Function to fetch charging session details
  void fetchChargingSessionDetails() async {
    String? username = widget.username;

    try {
      var response = await http.post(
        Uri.parse('http://122.166.210.142:9098/session/getChargingSessionDetails'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['value'] is List) {
          List<dynamic> chargingSessionData = data['value'];
          List<Map<String, dynamic>> sessionDetails =
              chargingSessionData.cast<Map<String, dynamic>>();
          setSessionDetails(sessionDetails);
        } else {
          throw Exception('Session details format is incorrect');
        }
      } else {
        throw Exception('Failed to load session details');
      }
    } catch (error) {
      print('Error fetching session details: $error');
      setState(() {
        isLoading = false; // Set loading state to false in case of error
      });
    }
  }

  void _showSessionDetailsModal(Map<String, dynamic> sessionData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.black, // Set background color to black
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SessionDetailsModal(sessionData: sessionData),
        );
      },
    );
  }

  Widget _buildShimmerEffect() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: List.generate(6, (index) {
            return Shimmer.fromColors(
              baseColor: Colors.grey[800]!,
              highlightColor: Colors.grey[700]!,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 20.0,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 5.0),
                  Container(
                    width: double.infinity,
                    height: 20.0,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20.0),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: isLoading // Show loading indicator while fetching data
                ? _buildShimmerEffect()
                : SingleChildScrollView(
                    child: Scrollbar(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0, left: 25),
                            child: Container(
                              child: const Row(
                                children: [
                                  Text(
                                    'Session History',
                                    style: TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          sessionDetails.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    padding: const EdgeInsets.all(20.0),
                                    child: const Center(
                                      child: Text(
                                        'No session history found.',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(left: 20.0, right: 20, bottom: 90),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E1E1E),
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    padding: const EdgeInsets.all(20.0),
                                    child: Center(
                                      child: Container(
                                        child: Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: Column(
                                            children: [
                                              for (int index = 0; index < sessionDetails.length; index++)
                                                InkWell(
                                                  onTap: () {
                                                    _showSessionDetailsModal(sessionDetails[index]);
                                                  },
                                                  child: Column(
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsets.all(5.0),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  Text(
                                                                    sessionDetails[index]['charger_id'].toString(),
                                                                    style: const TextStyle(
                                                                      fontSize: 19,
                                                                      color: Colors.white,
                                                                      fontWeight: FontWeight.bold,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 5),
                                                                  Text(
                                                                    sessionDetails[index]['start_time'] != null
                                                                        ? DateFormat('MM/dd/yyyy, hh:mm:ss a').format(
                                                                            DateTime.parse(sessionDetails[index]['stop_time']).toLocal(),
                                                                          )
                                                                        : "-",
                                                                    style: const TextStyle(
                                                                      fontSize: 13,
                                                                      color: Colors.white60,
                                                                    ),
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                            Column(
                                                              crossAxisAlignment: CrossAxisAlignment.end,
                                                              children: [
                                                                Text(
                                                                  '- Rs. ${sessionDetails[index]['price']}',
                                                                  style: const TextStyle(
                                                                    fontSize: 19,
                                                                    color: Colors.red,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 5),
                                                                Text(
                                                                  '${sessionDetails[index]['unit_consummed']} Kwh',
                                                                  style: const TextStyle(
                                                                    fontSize: 15,
                                                                    color: Colors.white60,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (index != sessionDetails.length - 1) CustomGradientDivider(),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
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

class SessionDetailsModal extends StatelessWidget {
  final Map<String, dynamic> sessionData;

  const SessionDetailsModal({Key? key, required this.sessionData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: Future.delayed(const Duration(milliseconds: 1000)), // Introduce delay for loading
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          return Container(
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
                      'Session Details',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomGradientDivider(),
                const SizedBox(height: 16),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade600,
                    child: const Icon(Icons.ev_station, color: Colors.white, size: 24),
                  ),
                  title: const Text(
                    'Charger ID',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  subtitle: Text(
                    '${sessionData['charger_id']}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade600,
                    child: const Icon(Icons.numbers, color: Colors.white, size: 24),
                  ),
                  title: const Text(
                    'Session ID',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  subtitle: Text(
                    '${sessionData['session_id']}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade600,
                    child: const Icon(Icons.timer, color: Colors.white, size: 24),
                  ),
                  title: const Text(
                    'Start Time',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  subtitle: Text(
                    sessionData['start_time'] != null
                        ? DateFormat('MM/dd/yyyy, hh:mm:ss a').format(DateTime.parse(sessionData['start_time']).toLocal())
                        : "-",
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade600,
                    child: const Icon(Icons.timer_off, color: Colors.white, size: 24),
                  ),
                  title: const Text(
                    'End Time',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  subtitle: Text(
                    sessionData['stop_time'] != null
                        ? DateFormat('MM/dd/yyyy, hh:mm:ss a').format(DateTime.parse(sessionData['stop_time']).toLocal())
                        : "-",
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade600,
                    child: const Icon(Icons.electric_bolt, color: Colors.white, size: 24),
                  ),
                  title: const Text(
                    'Units Consumed',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  subtitle: Text(
                    '${sessionData['unit_consummed']} Kwh',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade600,
                    child: const Icon(Icons.attach_money, color: Colors.white, size: 24),
                  ),
                  title: const Text(
                    'Price',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  subtitle: Text(
                    'Rs. ${sessionData['price']}',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
