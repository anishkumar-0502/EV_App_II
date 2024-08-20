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
  final String username;
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
  String activeFilter = 'All Chargers'; // Set 'Previously Used' as active filter by default
  bool isLoading = true; // State to manage loading
  GoogleMapController? mapController;
  LatLng? _currentPosition;
  final LatLng _center = const LatLng(12.9716, 77.5946);
  Set<Marker> _markers = {};
  bool isSearching = false; // Flag to prevent redundant state updates
  
@override
void initState() {
  super.initState();
  activeFilter = 'All Chargers'; // Set 'All Chargers' as active filter by default
  fetchAllChargers(); // Fetch all chargers data on initial load
  _getCurrentLocation(); // Fetch current location
}

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    rootBundle.loadString('assets/Map/map.json').then((String mapStyle) {
      mapController?.setMapStyle(mapStyle);
    });

    if (_currentPosition != null) {
      mapController?.animateCamera(
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

    mapController?.animateCamera(
      CameraUpdate.newLatLng(_currentPosition!),
    );
    _updateMarkers();
  }

  void _updateMarkers() {
    if (_currentPosition != null) {
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
  }

  Future<void> handleSearchRequest(String searchChargerID) async {
    if (isSearching) return; // Prevent redundant calls
    if (searchChargerID.isEmpty) {
      showErrorDialog(context, 'Please enter a charger ID.');
      return;
    }

    setState(() {
      isSearching = true; // Set the flag to true
    });

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
        print("AnishKumarAK");
        final data = json.decode(response.body);
        setState(() {
          this.searchChargerID = searchChargerID;
        });

        // Show dialog to select a connector
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.black,
          builder: (BuildContext context) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: ConnectorSelectionDialog(
                chargerData: data['socketGunConfig'] ?? {},
                onConnectorSelected: (connectorId, connectorType) {
                  updateConnectorUser(searchChargerID, connectorId, connectorType);
                },
              ),
            );
          },
        );
      } else {
        final errorData = json.decode(response.body);
        showErrorDialog(context, errorData['message']);
      }
    } catch (error) {
      showErrorDialog(context, error.toString());
    } finally {
      setState(() {
        isSearching = false; // Reset the flag
      });
    }
  }

  Future<void> updateConnectorUser(String searchChargerID, int connectorId, int connectorType) async {
    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:9098/updateConnectorUser'), // Replace with your actual backend URL
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'searchChargerID': searchChargerID,
          'Username': widget.username,
          'user_id': widget.userId,
          'connector_id': connectorId,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context); // Close the ConnectorSelectionDialog if open
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Charging(
              searchChargerID: searchChargerID,
              username: widget.username,
              userId: widget.userId,
              connector_id: connectorId,
              connector_type: connectorType,
            ),
          ),
        );
      } else {
        final errorData = json.decode(response.body);
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

  Future<void> fetchRecentSessionDetails() async {
    setState(() {
      isLoading = true; // Set loading to true
    });

    try {
      final response = await http.post(
        Uri.parse('http://122.166.210.142:9098/getRecentSessionDetails'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id':widget.userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recentSessions = data['data'] ?? [];
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

Future<void> fetchAllChargers() async {
  setState(() {
    isLoading = true; // Set loading to true
  });

  try {
    final response = await http.post(
      Uri.parse('http://122.166.210.142:9098/getAllChargersWithStatusAndPrice'), // Replace with your actual backend URL
      headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id':widget.userId,
        }),
      );


    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        availableChargers = data['data'] ?? [];
        activeFilter = 'All Chargers'; // Set active filter
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
                zoom: 16.0,
              ),
              markers: _markers,
              zoomControlsEnabled: false, // Disable default zoom controls
              myLocationEnabled: false, // Disable default location button
              myLocationButtonEnabled: false, // Disable default location button
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
                          fillColor: const Color(0xFF0E0E0E),
                          hintText: 'Search ChargerId...',
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
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E0E0E),
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
                      child: IconButton(
                        icon: const Icon(Icons.qr_code, color: Colors.white, size: 30),
                        onPressed: () {
                          navigateToQRViewExample();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeFilter == 'All Chargers' ? Colors.blue : const Color(0xFF0E0E0E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            activeFilter = 'All Chargers'; // Set 'All Chargers' as active filter
                          });
                          fetchAllChargers(); // Fetch all chargers data
                        },
                        icon: const Icon(Icons.ev_station, color: Colors.white),
                        label: const Text('All Chargers', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activeFilter == 'Previously Used' ? Colors.blue : const Color(0xFF0E0E0E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            activeFilter = 'Previously Used'; // Set 'Previously Used' as active filter
                          });
                          fetchRecentSessionDetails(); // Fetch recent session details on button press
                        },
                        icon: const Icon(Icons.history, color: Colors.white),
                        label: const Text('Previously Used', style: TextStyle(color: Colors.white)),
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
                    if (!isLoading && activeFilter == 'Previously Used')
                      for (var session in recentSessions)
                        _buildChargerCard(
                          context,
                          session['details']['charger_id'] ?? 'Unknown ID',
                          session['details']['model'] ?? 'Unknown Model',
                          session['status']['charger_status'] ?? 'Unknown Status',
                          "1.3 Km",
                          session['unit_price']?.toString() ?? 'Unknown Price',
                          session['status']['connector_id'] ?? 0, // Assuming connector_id is an int
                          session['details']['charger_accessibility']?.toString() ?? 'Unknown',
                        ),
                    if (!isLoading && activeFilter == 'All Chargers')
                      for (var charger in availableChargers)
                        for (var status in charger['status'] ?? [])
                          _buildChargerCard(
                            context,
                            charger['charger_id'] ?? 'Unknown ID',
                            charger['model'] ?? 'Unknown Model',
                            status['charger_status'] ?? 'Unknown Status',
                            "1.3 Km", // Replace with actual distance if available
                            charger['unit_price']?.toString() ?? 'Unknown Price',
                            status['connector_id'] ?? 'Unknown Last Updated',
                            charger['charger_accessibility']?.toString() ?? 'Unknown',
                          ),

                  ],
                ),
              ),
              const SizedBox(height: 28,), // Increased bottom margin
            ],
          ),
          Positioned(
            bottom: 200,
            right: 10,
            child: FloatingActionButton(
              backgroundColor: const Color.fromARGB(227, 76, 175, 79),
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
          Positioned(
            top: 170,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.black,
                  onPressed: () {
                    mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                  child: const Icon(Icons.zoom_in_map_rounded, color: Colors.white),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.black,
                  onPressed: () {
                    mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                  child: const Icon(Icons.zoom_out_map_rounded, color: Colors.red),
                ),
              ],
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
  String meter,
  String price,
  int connectorId,
  String accessType, // Add this parameter to determine Public or Private
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
return GestureDetector(
  onTap: () {
    handleSearchRequest(chargerId);
  },

    child: Stack(
      children: [
        // Card Container
        Container(
          width: 315,
          margin: const EdgeInsets.only(right: 28,top:20), // Added margin for spacing
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E0E),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "$chargerId - ",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            TextSpan(
                              text: "[$connectorId]",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue, // Change this to your desired color
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                              child: Row(
                                children: [

                                  IconButton(
                                    icon:
                                    const Icon(Icons.directions, color: Colors.red),
                                    onPressed: () {
                                      // Add functionality to navigate to the charger location on the map
                                    },
                                  ),
                                  Text('Navigate  ',style: TextStyle(color: Colors.white70),)
                                ],
                        ),
                      ),
                    ],
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
                        meter,
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
                              color: Colors.white70,
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
          SlantedLabel(accessType: accessType), // Add this widget here
      ],
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
          color: const Color(0xFF0E0E0E),
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
class ConnectorSelectionDialog extends StatefulWidget {
  final Map<String, dynamic> chargerData;
  final Function(int, int) onConnectorSelected;

  const ConnectorSelectionDialog({
    Key? key,
    required this.chargerData,
    required this.onConnectorSelected,
  }) : super(key: key);

  @override
  _ConnectorSelectionDialogState createState() => _ConnectorSelectionDialogState();
}

class _ConnectorSelectionDialogState extends State<ConnectorSelectionDialog> {
  int? selectedConnector;
  int? selectedConnectorType;

  bool _isFormValid() {
    return selectedConnector != null && selectedConnectorType != null;
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Connector',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomGradientDivider(),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            itemCount: widget.chargerData.keys.where((key) => key.startsWith('connector_')).length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3,
            ),
            itemBuilder: (BuildContext context, int index) {
              int connectorId = index + 1;
              String connectorKey = 'connector_${connectorId}_type';

              if (!widget.chargerData.containsKey(connectorKey) || widget.chargerData[connectorKey] == null) {
                return const SizedBox.shrink(); // Empty space if connector not available
              }

              int connectorType = widget.chargerData[connectorKey];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedConnector = connectorId;
                    selectedConnectorType = connectorType;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: selectedConnector == connectorId ? Colors.green : Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Connector $connectorId',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isFormValid()
                ? () {
              if (selectedConnector != null && selectedConnectorType != null) {
                widget.onConnectorSelected(selectedConnector!, selectedConnectorType!);
                Navigator.of(context).pop();
              }
            }
                : null,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return Colors.green.withOpacity(0.2); // Light green when disabled
                  }
                  return const Color(0xFF1C8B40); // Dark green when enabled
                },
              ),
              minimumSize: MaterialStateProperty.all(const Size(double.infinity, 50)),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              elevation: MaterialStateProperty.all(0),
              side: MaterialStateProperty.resolveWith<BorderSide>(
                    (Set<MaterialState> states) {
                  if (states.contains(MaterialState.disabled)) {
                    return const BorderSide(color: Colors.transparent); // No border when disabled
                  }
                  return const BorderSide(color: Colors.transparent); // No border when enabled
                },
              ),
            ),
            child: const Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}


class SlantedLabel extends StatelessWidget {
  final String accessType;

  const SlantedLabel({required this.accessType, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
  top: 0,
  right: 28,
  child: Stack(
    children: [
      ClipPath(
        clipper: SlantClipper(),
        child: Container(
          color: accessType == '1' ? const Color(0xFF0E0E0E) : const Color(0xFF0E0E0E), // Background color for the shape
          height: 40, // Adjust height as needed
          width: 100, // Adjust width as needed
        ),
      ),
     Positioned(
  right: 18,
  top: 5, // Adjust the position of the text
  child: Text(
    accessType == '1' ? 'Public' : 'Private', // Display "Public" or "Private"
    style: TextStyle(
      color: accessType == '1' ? Colors.green : Colors.yellow, // Blue for Public, Yellow for Private
      fontWeight: FontWeight.normal,
      fontSize: 15, // Adjust font size as needed
    ),
  ),
),

    ],
  ),
);

  }
}

class SlantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(20, 0); // Move right by 20 pixels at the top
    path.lineTo(0, size.height / 2); // Draw to the left middle point
    path.lineTo(20, size.height); // Draw back to the bottom left corner
    path.lineTo(size.width, size.height); // Draw to the bottom right corner
    path.lineTo(size.width, 0); // Draw to the top right corner
    path.close(); // Close the path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
