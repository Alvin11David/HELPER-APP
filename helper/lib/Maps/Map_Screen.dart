import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // Add this import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import '../Components/Bottom_Nav_Bar.dart';
import '../Components/User_Name.dart'; // Add this import

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final String _googleApiKey = 'AIzaSyBTk9548rr1JiKe1guF1i8z2wqHV8CZjRA';
  bool _showFilters = false;

  late GoogleMapController mapController;

  final LatLng _center = const LatLng(
    45.521563,
    -122.677433,
  ); // Fallback center
  LatLng? _currentPosition; // To store current location
  Set<Marker> _markers = {}; // To add a marker for current location

  List<Map<String, dynamic>> _workers = [];
  List<Map<String, dynamic>> _suggestions = [];

  int _selectedIndex = 1;

  late TextEditingController _controller;
  late FocusNode _focusNode;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add navigation logic if needed
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location services are disabled. Please enable them.'),
        ),
      );
      return;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, show a message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied. Please enable them in settings.',
          ),
        ),
      );
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    });

    // Move camera to current location
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition!, 15.0),
    );
  }

  Future<void> _loadWorkers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('serviceProviders')
        .get();
    _workers = snapshot.docs.map((doc) => doc.data()).toList();
    for (var worker in _workers) {
      final latLng = worker['workplaceLatLng'] as GeoPoint?;
      final portfolioFiles = worker['portfolioFiles'] as List<dynamic>?;
      if (latLng != null &&
          portfolioFiles != null &&
          portfolioFiles.isNotEmpty) {
        final imageUrl = portfolioFiles[0] as String;
        final marker = await _createMarkerFromImage(
          imageUrl,
          LatLng(latLng.latitude, latLng.longitude),
          worker['uid'] ?? 'unknown',
        );
        setState(() {
          _markers.add(marker);
        });
      }
    }
  }

  Future<Marker> _createMarkerFromImage(
    String url,
    LatLng position,
    String id,
  ) async {
    final response = await http.get(Uri.parse(url));
    final bytes = response.bodyBytes;
    final ui.Image image = await _loadImage(bytes);
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..isAntiAlias = true;
    final radius = 22.5;
    final rect = Rect.fromCircle(
      center: Offset(radius, radius),
      radius: radius,
    );
    canvas.clipPath(Path()..addOval(rect));
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, 45, 45),
      paint,
    );
    final picture = pictureRecorder.endRecording();
    final img = await picture.toImage(45, 45);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    return Marker(
      markerId: MarkerId(id),
      position: position,
      icon: BitmapDescriptor.bytes(pngBytes),
    );
  }

  Future<ui.Image> _loadImage(Uint8List bytes) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  void _onSearchChanged() {
    final query = _controller.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final filtered = _workers
        .where((worker) {
          final location = worker['workplaceLocationText']?.toLowerCase() ?? '';
          final category = worker['jobCategoryName']?.toLowerCase() ?? '';
          final categoryId = worker['jobCategoryId']?.toLowerCase() ?? '';
          final business = worker['businessName']?.toLowerCase() ?? '';
          return location.contains(query) ||
              category.contains(query) ||
              categoryId.contains(query) ||
              business.contains(query);
        })
        .map(
          (worker) => {
            'text':
                '${worker['businessName']} - ${worker['jobCategoryName']} in ${worker['workplaceLocationText']}',
            'worker': worker,
          },
        )
        .toList();
    setState(() => _suggestions = filtered);
  }

  void _showWorkerDetails(Map<String, dynamic> worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        width: double.infinity,
        height: 200,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16),
                  child: Text(
                    worker['businessName'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    worker['workplaceLocationText'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Available',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.black),
                  const SizedBox(width: 4),
                  const Text('4.6'),
                  const SizedBox(width: 4),
                  const Text('(200)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onSearchChanged);
    _getCurrentLocation().then(
      (_) => _loadWorkers(),
    ); // Request location on load and then load workers
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target:
                    _currentPosition ??
                    _center, // Use current position if available, else fallback
                zoom: 11.0,
              ),
              markers: _markers, // Add markers to the map
            ),
            Positioned(
              top: 20,
              left: w * 0.04,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      UserName(), // Replaced const Text('User', ...) with UserName()
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 20,
              right: w * 0.04,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.notifications, color: Colors.black),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 20,
              left: w * 0.04,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.menu, color: Colors.black),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      UserName(), // Replaced const Text('User', ...) with UserName()
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: 75,
              right: w * 0.04,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 40,
                    width: w * 0.76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 10),
                        Icon(Icons.search, color: Colors.black),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: 'Search for services here...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.black),
                            ),
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() => _showFilters = !_showFilters),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.tune, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 135,
              left: w * 0.04,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Available',
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('On Job', style: TextStyle(color: Colors.black)),
                  const SizedBox(width: 10),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Offline', style: TextStyle(color: Colors.black)),
                ],
              ),
            ),
            if (_suggestions.isNotEmpty)
              Positioned(
                top: 125,
                left: w * 0.04,
                right: w * 0.04,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = _suggestions[index];
                      return ListTile(
                        leading: Icon(Icons.search, color: Colors.black),
                        title: Text(
                          suggestion['text'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          final worker = suggestion['worker'];
                          final latLng = worker['workplaceLatLng'] as GeoPoint?;
                          if (latLng != null && mapController != null) {
                            mapController.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(latLng.latitude, latLng.longitude),
                                15.0,
                              ),
                            );
                          }
                          _showWorkerDetails(worker);
                          setState(() => _suggestions = []);
                          _focusNode.unfocus();
                        },
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }
}
