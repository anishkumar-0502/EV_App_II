import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
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
  List<Map<String, dynamic>> transactionDetails = [];

  @override
  void initState() {
    super.initState();
    fetchChargingSessionDetails();
  }

  // Function to set session details
  void setSessionDetails(List<Map<String, dynamic>> value) {
    setState(() {
      sessionDetails = value;
    });
  }

  // Function to set transaction details
  void setTransactionDetails(List<Map<String, dynamic>> value) {
    setState(() {
      transactionDetails = value;
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

  void _showsessionhelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: const HelpModal(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showsessionhelp,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(left: 15.5,top: 15.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Sessions',
                  style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8), // Space between text widgets
                Text(
                  'Explore the details of your charging session',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                SizedBox(height: 16), // Space after the text
                // Additional widgets go here
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Scrollbar(
                child: Column(
                  children: [
                    sessionDetails.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.all(19.0),
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
                      padding: const EdgeInsets.only(left: 15.0, right: 20, bottom: 90),
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

  String _getConnectorTypeName(int? connectorType) {
    switch (connectorType) {
      case 1:
        return 'Socket';
      case 2:
        return 'Gun';

      default:
        return 'Unknown';
    }
  }
  @override
  Widget build(BuildContext context) {
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
              'Connector Id',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            subtitle: Text(
              '${sessionData['connector_id']}',
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
              'Connector Type',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            subtitle: Text(
              _getConnectorTypeName(sessionData['connector_type']),
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
              child: const Icon(Icons.access_time, color: Colors.white, size: 24),
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
              child: const Icon(Icons.stop, color: Colors.white, size: 24),
            ),
            title: const Text(
              'Stop Time',
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
              child: const Icon(Icons.electric_car, color: Colors.white, size: 24),
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
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}


class HelpModal extends StatelessWidget {
  const HelpModal({super.key});

  @override
  Widget build(BuildContext context) {
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
                'Help & Support',
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
          const Text(
            'Session History',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'This page displays a list of your past charging sessions. You can tap on any session to view detailed information, including charger ID, session ID, start time, end time, units consumed, and price.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Viewing Session Details',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'To view details of a specific session, tap on the session entry in the list. This will open a modal at the bottom of the screen displaying detailed information about the session.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Help & Support',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'For any further assistance or issues, please contact our support team @ support@outdidtech.com. You can find contact details in the app settings or visit our website for more help.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

