import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../Charging/charging.dart';
import '../../utilities/QR/qrscanner.dart';
import '../../utilities/Alert/alert_banner.dart';

class HomeContent extends StatefulWidget {
  final String? username;
  final int? userId;

  const HomeContent({super.key, required this.username, required this.userId});

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController _searchController = TextEditingController();
  String searchChargerID = '';
  List availableChargers = [];
  List recentSessions = [];
  String activeFilter = 'Previously Used'; // Initialize with 'Previously Used'
  bool isLoading = true; // State to manage loading
  late GoogleMapController mapController;
  LatLng? _currentPosition;
  final LatLng _center = const LatLng(45.521563, -122.677433);
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    fetchRecentSessionDetails(); // Fetch recent session details on initial load
    _getCurrentLocation(); // Fetch current location
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    rootBundle.loadString('assets/Map/map.json').then((String mapStyle) {
      mapController.setMapStyle(mapStyle);
    });

    if (_currentPosition != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLng(_currentPosition!),
      );
      _updateMarkers();
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    if (mapController != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLng(_currentPosition!),
      );
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    });
  }

  Future<void> handleSearchRequest(String searchChargerID) async {
    if (searchChargerID.isEmpty) {
      showErrorDialog(context, 'Please enter a charger ID.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:9098/searchCharger'), // Replace with your actual backend URL
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'searchChargerID': searchChargerID,
          'Username': widget.username,
          'user_id': widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          this.searchChargerID = searchChargerID;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Charging(
              searchChargerID: searchChargerID,
              username: widget.username,
            ),
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        print(errorData);
        showErrorDialog(context, errorData['message']);
      }
    } catch (error) {
      showErrorDialog(context, error.toString());
    }
  }

  void navigateToQRViewExample() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => QRViewExample(handleSearchRequestCallback: handleSearchRequest)),
    );

    if (scannedCode != null) {
      setState(() {
        searchChargerID = scannedCode;
      });
      handleSearchRequest(scannedCode);
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.black, // Set background color to black
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: ErrorDetails(errorData: message),
        );
      },
    ).then((_) {
      Navigator.of(context).popUntil((route) => route.isFirst); // Close the QR code scanner page and return to the Home Page
    });
  }

  Future<void> fetchAvailableChargers() async {
    setState(() {
      isLoading = true; // Set loading to true
    });

    try {
      final response = await http.get(
        Uri.parse('http://122.166.210.142:9098/filterChargersWithAvailableStatus'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          availableChargers = data['availableChargers'];
          activeFilter = 'Available Chargers'; // Set active filter
          isLoading = false; // Set loading to false
        });
      } else {
        final errorData = json.decode(response.body);
        showErrorDialog(context, errorData['message']);
        setState(() {
          isLoading = false; // Set loading to false
        });

      }
    } catch (error) {
      showErrorDialog(context, error.toString());
      setState(() {
        isLoading = false; // Set loading to false
      });
    }
  }

  Future<void> fetchRecentSessionDetails() async {
    setState(() {
      isLoading = true; // Set loading to true
    });

    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:9098/getRecentSessionDetails'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': widget.username,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recentSessions = data['data'];
          activeFilter = 'Previously Used'; // Set active filter
          isLoading = false; // Set loading to false
        });
      } else {
        final errorData = json.decode(response.body);
        showErrorDialog(context, errorData['message']);
        setState(() {
          isLoading = false; // Set loading to false
        });
      }
    } catch (error) {
      showErrorDialog(context, error.toString());
      setState(() {
        isLoading = false; // Set loading to false
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Google Map
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? _center,
                zoom: 15.0,
              ),
              markers: _markers,
            ),
          ),
          // Foreground content
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (value) {
                          handleSearchRequest(value);
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFF1E1E1E),
                          hintText: 'Search location...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: const Icon(Icons.search, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.qr_code, color: Colors.white, size: 30),
                      onPressed: () {
                        navigateToQRViewExample();
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeFilter == 'Previously Used' ? Colors.blue : const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          fetchRecentSessionDetails(); // Fetch recent session details on button press
                        },
                        icon: const Icon(Icons.history, color: Colors.white),
                        label: const Text('Previously Used', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeFilter == 'Available Chargers' ? Colors.blue : const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          fetchAvailableChargers(); // Fetch available chargers on button press
                        },
                        icon: const Icon(Icons.ev_station, color: Colors.white),
                        label: const Text('Available Chargers', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeFilter == 'All Chargers' ? Colors.blue : const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                            activeFilter = 'All Chargers';
                            // Fetch and set all chargers data if needed
                          });
                          // Simulate loading data
                          Future.delayed(const Duration(milliseconds: 900), () {
                            setState(() {
                              isLoading = false;
                            });
                          });
                        },
                        icon: const Icon(Icons.ev_station, color: Colors.white),
                        label: const Text('All Chargers', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(), // Added spacer to push the cards to the bottom
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 15),
                    if (isLoading)
                      for (var i = 0; i < 3; i++) _buildShimmerCard(), // Show shimmer cards while loading
                    if (!isLoading && activeFilter == 'Available Chargers')
                      for (var charger in availableChargers)
                        _buildChargerCard(
                          context,
                          charger['details']['charger_id'],
                          charger['details']['model'],
                          charger['charger_status'],
                          charger['details']['lat'] + ', ' + charger['details']['long'],
                          charger['details']['unit_price'].toString(),
                        ),
                    if (!isLoading && activeFilter == 'Previously Used')
                      for (var session in recentSessions)
                        _buildChargerCard(
                          context,
                          session['details']['charger_id'],
                          session['details']['model'],
                          session['status']['charger_status'],
                          session['details']['lat'] + ', ' + session['details']['long'],
                          session['details']['unit_price'].toString(),
                        ),
                    const SizedBox(width: 15),
                  ],
                ),
              ),
              const SizedBox(height: 26), // Increased bottom margin
            ],
          ),
          Positioned(
            bottom: 160,
            right: 10,
            child: FloatingActionButton(
              backgroundColor: const Color.fromARGB(227, 76, 175, 79),
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargerCard(
    BuildContext context,
    String chargerId,
    String model,
    String status,
    String location,
    String price,
  ) {
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case "Available":
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case "Unavailable":
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case "Preparing":
        statusColor = Colors.yellow;
        statusIcon = Icons.hourglass_empty;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 15.0), // Added margin for spacing
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chargerId,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                model,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.currency_rupee,
                        color: Colors.orange,
                        size: 14,
                      ),
                      Text(
                        "$price per unit",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 15.0), // Added margin for spacing
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 20,
                color: Colors.white,
              ),
              const SizedBox(height: 5),
              Container(
                width: 80,
                height: 20,
                color: Colors.white,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 20,
                    height: 20,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Container(
                width: double.infinity,
                height: 20,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
